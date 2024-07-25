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
                            let thread = self.toThread(post)
                            windowState.route.append(thread)
                        }
                }
            }
        }
        .navigationTitle(board.title)
        .task(id: board.id) {
            await loadBoard()
        }
        .refreshable {
            await refresh()
        }
    }
    
    private func toThread(_ post: Post) -> ViewableItem {
        return ViewableItem.thread(board, Thread(id: post.id,
                                                 boardId: board.id,
                                                 author: post.author,
                                                 date: post.date,
                                                 subject: post.subject,
                                                 content: post.content,
                                                 sticky: post.sticky,
                                                 closed: post.closed,
                                                 spoileredImage: post.spoileredImage,
                                                 attachment: post.attachment,
                                                 statistics: post.threadStatistics ?? ThreadStatistics(replies: 0, images: 0, uniquePosters: 0, bumpLimit: false, imageLimit: false, page: 0)))
    }
    
    private func updateData() async throws {
        let threads = try await FourChanDataProvider().getCatalog(for: board)
        viewModel.threads = ContentProvider.instance.processPosts(threads.map { $0.toPost() }, in: board)
    }
    
    private func loadBoard() async {
        do {
            viewModel.state = .loading
            
            try await updateData()
            viewModel.state = .ready
        } catch {
            print(error)
            viewModel.state = .error("Failed to load boards: \(error.localizedDescription)")
        }
    }
    
    private func refresh() async {
        do {
            try await updateData()
        } catch {
            viewModel.state = .error("Failed to load boards: \(error.localizedDescription)")
        }
    }
}

// MARK: - View Model

@Observable
fileprivate class ViewModel {
    var state: State = .loading
    var threads: [Post] = []
    
    enum State {
        case loading
        case ready
        case error(_ message: String)
    }
}

// MARK: - Previews

#Preview {
    BoardView(board: Board(id: "a",
                         title: "Anime",
                         description: "",
                         features: .none))
}
