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
    let boardId: String
    @Environment(WindowState.self) private var windowState
    @State private var viewModel: ViewModel = .init()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                
            case .error(let message):
                Text(message)
                
            case .ready:
                List(viewModel.threads) { post in
                    PostView(post: post)
                        .onTapGesture {
                            windowState.route.append(ViewableItem.thread(boardId: boardId, threadId: post.threadId))
                        }
                }
            }
        }
        .navigationTitle(viewModel.board?.title ?? boardId)
        .task(id: boardId) {
            await loadBoard()
        }
        .refreshable {
            await refresh()
        }
    }
    
    private func updateData() async throws -> ViewModel.State {
        guard let board = try await FourChanDataProvider().getBoard(for: boardId) else {
            return .error("Board \(boardId) does not exist")
        }
        
        let threads = try await FourChanDataProvider().getCatalog(for: board)
        
        viewModel.board = board
        viewModel.threads = ContentProvider.instance.processPosts(threads.map { $0.toPost() }, in: board)
        return .ready
    }
    
    private func loadBoard() async {
        do {
            viewModel.state = .loading
            
            viewModel.state = try await updateData()
        } catch {
            viewModel.state = .error("Failed to load boards: \(error.localizedDescription)")
        }
    }
    
    private func refresh() async {
        do {
            viewModel.state = try await updateData()
        } catch {
            viewModel.state = .error("Failed to load boards: \(error.localizedDescription)")
        }
    }
}

// MARK: - View Model

@Observable
fileprivate class ViewModel {
    var state: State = .loading
    var board: Board?
    var threads: [Post] = []
    
    enum State {
        case loading
        case ready
        case error(_ message: String)
    }
}

// MARK: - Previews

#Preview {
    BoardView(boardId: "a")
}
