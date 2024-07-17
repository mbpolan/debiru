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
            viewModel.threads = try await FourChanDataProvider().getCatalog(for: board)
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        List(viewModel.threads) { thread in
            Text("\(thread.id)")
        }
        .task {
            await loadBoard()
        }
    }
}

// MARK: - View Model

@Observable
fileprivate class ViewModel {
    var threads: [Thread] = []
}

// MARK: - Previews

#Preview {
    BoardView(board: Board(id: "a", title: "Anime", description: "", features: .none))
}
