//
//  BoardView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

// MARK: - View

/// A view that displays threads in a particular board.
struct BoardView: View {
    let board: Board
    @State private var viewModel: ViewModel = .init()
    
    private func loadBoard() async {
        do {
            viewModel.state = .loading
            viewModel.threads = try await FourChanDataProvider().getCatalog(for: board)
            
            viewModel.state = .ready
        } catch {
            print(error)
            viewModel.state = .error("Failed to load boards: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                
            case .error(let message):
                Text(message)
                
            case .ready:
                List(viewModel.threads) { thread in
                    PostView(post: thread.toPost())
                }
            }
        }
        .navigationTitle(board.title)
        .task {
            await loadBoard()
        }
    }
}

// MARK: - View Model

@Observable
fileprivate class ViewModel {
    var state: State = .loading
    var threads: [Thread] = []
    
    enum State {
        case loading
        case ready
        case error(_ message: String)
    }
}

// MARK: - Previews

#Preview {
    BoardView(board: Board(id: "a", title: "Anime", description: "", features: .none))
}
