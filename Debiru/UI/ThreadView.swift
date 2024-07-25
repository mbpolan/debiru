//
//  ThreadView.swift
//  Debiru
//
//  Created by Mike Polan on 7/24/24.
//

import SwiftUI

// MARK: - View

/// A view that displays posts in a single thread.
struct ThreadView: View {
    let boardId: String
    let threadId: Int
    @State private var viewModel: ViewModel = .init()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                
            case .error(let message):
                Text(message)
                
            case .ready:
                List(viewModel.posts, children: \.children) { item in
                    PostView(post: item.post)
                }
            }
        }
        .task(id: threadId) {
            await loadThread()
        }
        .refreshable {
            await refresh()
        }
        .navigationTitle(viewModel.thread?.subject ?? viewModel.board?.title ?? "")
        #if os(macOS)
        .navigationSubtitle(viewModel.board?.title ?? "")
        #endif
    }
    
    private func updateData() async throws -> ViewModel.State {
        guard let board = try await FourChanDataProvider().getBoard(for: boardId) else {
            return .error("Board \(boardId) does not exist")
        }
        
        let data = try await FourChanDataProvider().getPosts(for: threadId, in: boardId)
        viewModel.posts = ContentProvider.instance.processPosts(data, in: board).map { ThreadPost(post: $0) }
        return .ready
    }
    
    private func loadThread() async {
        do {
            viewModel.state = .loading
            viewModel.state = try await updateData()
        } catch {
            viewModel.state = .error("Failed to load posts: \(error.localizedDescription)")
        }
    }
    
    private func refresh() async {
        do {
            viewModel.state = try await updateData()
        } catch {
            viewModel.state = .error("Failed to load posts: \(error.localizedDescription)")
        }
    }
}

@Observable
fileprivate class ViewModel {
    var state: State = .loading
    var board: Board?
    var thread: Thread?
    var posts: [ThreadPost] = []
    
    enum State {
        case loading
        case ready
        case error(_ message: String)
    }
}

class ThreadPost: Identifiable {
    let post: Post
    var children: [ThreadPost]? = nil
    
    init(post: Post) {
        self.post = post
    }
    
    var id: Int {
        return post.id
    }
}
