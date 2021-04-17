//
//  ThreadWatcher.swift
//  Debiru
//
//  Created by Mike Polan on 4/17/21.
//

import Combine
import Foundation

class ThreadWatcher {
    static var shared: ThreadWatcher?
    
    let appState: AppState
    let dataProvider: DataProvider
    private var timer: Timer?
    
    init(appState: AppState, dataProvider: DataProvider = FourChanDataProvider()) {
        self.appState = appState
        self.dataProvider = dataProvider
        ThreadWatcher.shared = self
    }
    
    func start() {
        timer = scheduleNextThreadCheck()
    }
    
    private func handleCheckWatchedThreads(_ timer: Timer) {
        let group = DispatchGroup()
        var updatedWatchedThreads: [WatchedThread] = []
        var tasks: [AnyCancellable] = []
        
        appState.watchedThreads.forEach { watchedThread in
            group.enter()
            
            print("Checking: \(watchedThread.thread.boardId) - \(watchedThread.id)")
            
            // fetch posts for this thread
            let task = dataProvider.getPosts(for: watchedThread.thread) { result in
                switch result {
                case .success(let posts):
                    // has the thread been archived since the last time we checked?
                    let archived = posts.first?.archived ?? false
                    
                    // are there any new posts since the last known post was checked?
                    let lastKnownIndex = posts
                        .firstIndex { $0.id == watchedThread.lastPostId } ?? 0
                    
                    let newPosts = posts.count - lastKnownIndex - 1
                    print("New: \(watchedThread.thread.boardId) - \(watchedThread.id) = \(newPosts)")
                    
                    updatedWatchedThreads.append(WatchedThread(
                                                    thread: watchedThread.thread,
                                                    lastPostId: watchedThread.lastPostId,
                                                    totalNewPosts: newPosts,
                                                    nowArchived: archived,
                                                    nowDeleted: false))
                    
                case .failure(let error):
                    print("*** ERROR: \(error.localizedDescription)")
                    // TODO: handle errors and edge cases where the thread has been deleted
                }
                
                group.leave()
            }
            
            if let task = task {
                tasks.append(task)
            }
        }
        
        group.notify(queue: .main) { [weak self, tasks] in
            print("**** Update sweep finished for \(tasks.count) threads")
            
            // track different types of updates that can occur
            var unwatched = false
            var deleted = false
            var newPosts = false
            var archived = false
            
            // track threads that previously had no new replies, but now do
            var activeThreads: [WatchedThread] = []
            
            updatedWatchedThreads.forEach { updatedThread in
                // find the previous watched metrics we have for this thread
                let previousThread = self?.appState.watchedThreads.first {
                    return $0.id == updatedThread.id &&
                        $0.thread.boardId == updatedThread.thread.boardId
                }
                
                // has there been a change to this thread since the last time we checked?
                if let previousThread = previousThread {
                    deleted = previousThread.nowDeleted != updatedThread.nowDeleted || deleted
                    newPosts = previousThread.totalNewPosts != updatedThread.totalNewPosts || newPosts
                    archived = previousThread.nowArchived != updatedThread.nowArchived || archived
                    
                    // has a thread received its first new reply?
                    if previousThread.totalNewPosts == 0 && updatedThread.totalNewPosts > 0 {
                        activeThreads.append(updatedThread)
                    }
                } else {
                    // this thread was unwatched while we were checking for updates
                    unwatched = true
                }
            }
            
            // if at least one thread has new post activity, push a notification
            if !activeThreads.isEmpty {
                NotificationManager.shared.pushNewPostNotification()
            }
            
            // update the app state with our newly gathered thread statistics, and schedule
            // the next iteration. however, only update the state if at least some kind of
            // change has happened, otherwise we unnecessarily will cause redraws.
            if unwatched || deleted || newPosts || archived {
                self?.appState.watchedThreads = updatedWatchedThreads
            }
            
            self?.timer = self?.scheduleNextThreadCheck()
        }
    }
    
    private func scheduleNextThreadCheck() -> Timer {
        return Timer.scheduledTimer(
            withTimeInterval: TimeInterval(10),
            repeats: false,
            block: handleCheckWatchedThreads)
    }
}
