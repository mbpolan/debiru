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
                }
            }
        }
        .padding(1)
    }
    
    private var selectableBoards: [Board] {
        return appState.boards.sorted(by: { $0.id < $1.id })
    }
    
    private var watchedThreads: [WatchedThread] {
        if !viewModel.selectedBoard.isEmpty {
            return appState.watchedThreads.filter { $0.thread.boardId == viewModel.selectedBoard }
        }
        
        return appState.watchedThreads
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
