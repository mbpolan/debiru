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
                List(watchedThreads, id: \.self) { thread in
                    ThreadListItemView(thread)
                }
            }
        }
        .padding(1)
    }
    
    private var selectableBoards: [Board] {
        return appState.boards.sorted(by: { $0.id < $1.id })
    }
    
    private var watchedThreads: [Thread] {
        if !viewModel.selectedBoard.isEmpty {
            return appState.watchedThreads.filter { $0.boardId == viewModel.selectedBoard }
        }
        
        return appState.watchedThreads
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
