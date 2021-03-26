//
//  ContentView.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Combine
import SwiftUI

// MARK: - View

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: ContentViewModel = ContentViewModel()
    
    private let dataProvider: DataProvider
    private let showBoardPublisher = NotificationCenter.default.publisher(for: .showBoard)
    private let showThreadPublisher = NotificationCenter.default.publisher(for: .showThread)
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        NavigationView {
            SidebarView()
            
            switch appState.currentItem {
            case .board(_):
                CatalogView()
            
            case .thread(_):
                ThreadView()
                
            default:
                if viewModel.pendingBoards != nil {
                    ProgressView("Loading")
                } else {
                    Text("unknown?")
                }
            }
        }
        .environmentObject(appState)
        .onAppear {
            viewModel.pendingBoards = dataProvider.getBoards(handleBoards)
        }
        .onReceive(showBoardPublisher) { event in
            if let board = event.object as? Board {
                handleShowBoard(board)
            }
        }
        .onReceive(showThreadPublisher) { event in
            if let thread = event.object as? Thread {
                handleShowThread(thread)
            }
        }
        .sheet(item: $viewModel.error, onDismiss: {
            viewModel.error = nil
        }) { error in
            VStack {
                Text(error.message)
                HStack {
                    Spacer()
                    Button("OK") {
                        viewModel.error = nil
                    }
                }
            }
            .padding()
        }
    }
    
    private func handleShowBoard(_ board: Board) {
        appState.currentItem = .board(board)
        
        // add this board to our open items view, if it's not there already
        if !appState.openItems.contains(where: { $0 == .board(board) }) {
            appState.openItems.append(.board(board))
        }
    }
    
    private func handleShowThread(_ thread: Thread) {
        appState.currentItem = .thread(thread)
        
        // add this thread to our open items view, if it's not there already
        if !appState.openItems.contains(where: { $0 == .thread(thread) }) {
            appState.openItems.append(.thread(thread))
        }
    }
    
    private func handleBoards(_ result: Result<[Board], Error>) {
        switch result {
        case .success(let boards):
            appState.boards = boards
        case .failure(let error):
            viewModel.error = ContentViewModel.ViewError(message: error.localizedDescription)
        }
        
        viewModel.pendingBoards = nil
    }
}

// MARK: - View Model

class ContentViewModel: ObservableObject {
    @Published var pendingBoards: AnyCancellable?
    @Published var error: ViewError?
    
    struct ViewError: Identifiable {
        let message: String
        var id: UUID {
            UUID()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
}
