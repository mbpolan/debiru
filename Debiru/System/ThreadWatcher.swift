//
//  ThreadWatcher.swift
//  Debiru
//
//  Created by Mike Polan on 4/17/21.
//

import Combine
import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class ThreadWatcher {
    static var shared: ThreadWatcher?
    
    let appState: AppState
    let dataProvider: DataProvider
    private var timer: Task<Void, Never>?
    
    init(appState: AppState, dataProvider: DataProvider = FourChanDataProvider()) {
        self.appState = appState
        self.dataProvider = dataProvider
        ThreadWatcher.shared = self
    }
    
    func start() {
        timer = Task {
            try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            
            await self.handleCheckWatchedThreads()
        }
    }
    
    private func handleCheckWatchedThreads() async {
        let results = await withTaskGroup(of: WatchedThread?.self,
                                          returning: [WatchedThread].self) { taskGroup in
            
            for watchedThread in appState.watchedThreads {
                taskGroup.addTask { () -> WatchedThread? in
                    // do not process deleted threads
                    if watchedThread.nowDeleted {
                        print("Ignoring deleted: \(watchedThread.thread.boardId) - \(watchedThread.id)")
                        return watchedThread
                    }
                    
                    print("Checking: \(watchedThread.thread.boardId) - \(watchedThread.id)")
                    
                    // fetch posts for this thread
                    do {
                        let posts = try await self.dataProvider.getPosts(for: watchedThread.thread)
                        
                        // has the thread been archived since the last time we checked?
                        let archived = posts.first?.archived ?? false
                        
                        // are there any new posts since the last known post was checked?
                        let lastKnownIndex = posts
                            .firstIndex { $0.id == watchedThread.currentLastPostId } ?? 0
                        
                        let newPosts = posts.count - lastKnownIndex - 1
                        print("New: \(watchedThread.thread.boardId) - \(watchedThread.id) = \(newPosts)")
                        
                        return WatchedThread(
                            thread: watchedThread.thread,
                            lastPostId: watchedThread.lastPostId,
                            currentLastPostId: posts.last?.id ?? watchedThread.lastPostId,
                            totalNewPosts: newPosts,
                            nowArchived: archived,
                            nowDeleted: false)
                    } catch {
                        switch error {
                        case NetworkError.notFound:
                            // mark this thread as deleted so we don't consider it anymore
                            return WatchedThread(
                                thread: watchedThread.thread,
                                lastPostId: watchedThread.lastPostId,
                                currentLastPostId: watchedThread.lastPostId,
                                totalNewPosts: 0,
                                nowArchived: false,
                                nowDeleted: true)
                        default:
                            print("*** ERROR: \(error.localizedDescription)")
                            return nil
                        }
                    }
                }
            }
            
            var watchedThreads: [WatchedThread] = []
            for await result in taskGroup {
                if let watchedThread = result {
                    watchedThreads.append(watchedThread)
                }
            }
            
            return watchedThreads
        }
        
        DispatchQueue.main.async { [weak self, results] in
            print("**** Update sweep finished for \(results.count) threads")
            
            guard let `self` = self else { return }
            
            // track different types of updates that can occur
            var unwatched = false
            var deleted = false
            var newPosts = false
            var archived = false
            var countNewPosts = 0
            
            // track threads that previously had no new replies, but now do
            var activeThreads: [WatchedThread] = []
            
            results.forEach { updatedThread in
                // find the previous watched metrics we have for this thread
                let previousThread = self.appState.watchedThreads.first {
                    return $0.id == updatedThread.id &&
                        $0.thread.boardId == updatedThread.thread.boardId
                }
                
                // has there been a change to this thread since the last time we checked?
                if let previousThread = previousThread {
                    deleted = previousThread.nowDeleted != updatedThread.nowDeleted || deleted
                    newPosts = previousThread.totalNewPosts != updatedThread.totalNewPosts || newPosts
                    archived = previousThread.nowArchived != updatedThread.nowArchived || archived
                    countNewPosts += updatedThread.totalNewPosts
                    
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
                NotificationManager.shared?.pushNewPostNotification()
            }
            
            // update the dock tile badge to reflect the total count of new posts
            NotificationManager.shared?.updateApplicationBadge(withPostCount: countNewPosts)
            
            // avoid rerendering when nothing has changed in terms of post counts
            if self.appState.newPostCount != countNewPosts {
                self.appState.newPostCount = countNewPosts
            }
            
            // update the app state with our newly gathered thread statistics, and schedule
            // the next iteration. however, only update the state if at least some kind of
            // change has happened, otherwise we unnecessarily will cause redraws.
            if unwatched || deleted || newPosts || archived {
                self.appState.watchedThreads = results
            }
        }
    }
}
