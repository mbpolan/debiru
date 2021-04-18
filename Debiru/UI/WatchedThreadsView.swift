//
//  WatchedThreadsView.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

import SwiftUI

// MARK: - View

struct WatchedThreadsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel = WatchedThreadsViewModel()
    
    var body: some View {
        VStack {
            Picker(selection: $viewModel.selectedBoard, label: Text("")) {
                Text("All")
                    .frame(maxWidth: .infinity)
                    .tag("")
                
                Divider()
                
                ForEach(selectableBoards, id: \.self) { board in
                    Text("/\(board.id)/ - \(board.title)")
                        .frame(maxWidth: .infinity)
                        .tag(board.id)
                }
            }
            
            if watchedThreads.isEmpty {
                Spacer()
                Text("No watched threads")
                Spacer()
            } else {
                List(watchedThreads, id: \.self) { watchedThread in
                    HStack(alignment: .firstTextBaseline) {
                        ThreadListItemView(watchedThread.thread)
                        
                        Spacer()
                        
                        makeBadge(watchedThread)
                    }
                    .onTapGesture {
                        handleShowThread(watchedThread)
                    }
                    .contextMenu {
                        Button("Remove") {
                            handleRemoveWatchedThread(watchedThread)
                        }
                    }
                }
            }
        }
        .padding(1)
    }
    
    private var selectableBoards: [Board] {
        return appState.boards.sorted(by: { $0.id < $1.id })
    }
    
    private var watchedThreads: [WatchedThread] {
        var threads: [WatchedThread] = appState.watchedThreads
        if !viewModel.selectedBoard.isEmpty {
            threads = appState.watchedThreads.filter { $0.thread.boardId == viewModel.selectedBoard }
        }
        
        // ensure a consistent ordering: first by total new posts then by thread id in case
        // of ties
        return threads.sorted(by: {
            if $0.totalNewPosts == $1.totalNewPosts {
                return $0.thread.id < $1.thread.id
            }
            
            return $0.totalNewPosts > $1.totalNewPosts
        })
    }
    
    private func makeBadge(_ watchedThread: WatchedThread) -> AnyView? {
        var badge: AnyView? = nil
        
        if watchedThread.totalNewPosts > 0 {
            badge = ZStack {
                Circle()
                    .foregroundColor(.red)
                
                Text("\(watchedThread.totalNewPosts)")
                    .foregroundColor(.white)
            }
            .toErasedView()
            
        } else if watchedThread.nowArchived {
            badge = Image(systemName: "archivebox")
                .foregroundColor(.red)
                .toErasedView()
            
        } else if watchedThread.nowDeleted {
            badge = Image(systemName: "xmark.bin")
                .foregroundColor(.red)
                .toErasedView()
        }
        
        return badge?.frame(width: 20, height: 20)
            .toErasedView()
    }
    
    private func handleShowThread(_ watchedThread: WatchedThread) {
        NotificationCenter.default.post(name: .showThread, object: watchedThread)
    }
    
    private func handleRemoveWatchedThread(_ watchedThread: WatchedThread) {
        guard let index = appState.watchedThreads.firstIndex(of: watchedThread) else { return }
        
        // remove the thread and post a request to save app state
        appState.watchedThreads.remove(at: index)
        NotificationCenter.default.post(name: .saveAppState, object: nil)
    }
}

// MARK: - View Model

class WatchedThreadsViewModel: ObservableObject {
    @Published var selectedBoard: String = ""
}

// MARK: - Preview

struct WatchedThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        WatchedThreadsView()
            .environmentObject(AppState())
    }
}
