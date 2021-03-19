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
    @StateObject private var appState: AppState = AppState()
    @ObservedObject private var viewModel: ContentViewModel = ContentViewModel()
    
    private let dataProvider: DataProvider
    private let showBoardPublisher = NotificationCenter.default.publisher(for: .showBoard)
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        NavigationView {
            SidebarView()
            
            if viewModel.pendingBoards != nil {
                ProgressView("Loading")
            } else if let board = appState.boards.first(where: { $0.id == appState.currentBoardId }) {
                CatalogView(board: board)
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
        appState.currentBoardId = board.id
        
        // add this board to our open items view, if it's not there already
        if !appState.openItems.contains(where: { $0 == .board(board) }) {
            appState.openItems.append(.board(board))
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
