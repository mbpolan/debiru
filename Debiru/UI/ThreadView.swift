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
    let board: Board
    let thread: Thread
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
        .task(id: thread.id) {
            await loadThread()
        }
        .refreshable {
            await refresh()
        }
        .navigationTitle("Thread")
    }
    
    private func updateData() async throws {
        let data = try await FourChanDataProvider().getPosts(for: thread)
        viewModel.posts = ContentProvider.instance.processPosts(data, in: board).map { ThreadPost(post: $0) }
    }
    
    private func loadThread() async {
        do {
            viewModel.state = .loading
            
            try await updateData()
            viewModel.state = .ready
        } catch {
            print(error)
            viewModel.state = .error("Failed to load posts: \(error.localizedDescription)")
        }
    }
    
    private func refresh() async {
        do {
            try await updateData()
        } catch {
            viewModel.state = .error("Failed to load posts: \(error.localizedDescription)")
        }
    }
}

@Observable
fileprivate class ViewModel {
    var state: State = .loading
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
