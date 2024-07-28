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
    @Environment(WindowState.self) private var windowState
    @State private var viewModel: ViewModel = .init()
    private static let dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                
            case .error(let message):
                Text(message)
                
            case .ready:
                List(self.posts, children: \.children) { item in
                    PostView(post: item.post, onAssetAction: handleAssetAction)
                        .postViewListItem()
                }
            }
        }
        .navigationTitle(viewModel.thread?.subject ?? viewModel.board?.title ?? "#\(threadId)")
        #if os(macOS)
        .navigationSubtitle(viewModel.board?.title ?? "")
        #endif
        .postList()
        .searchable(text: $viewModel.filter)
        .task(id: threadId) {
            await loadThread()
        }
        .refreshable {
            await refresh()
        }
        .toolbar {
            ToolbarItemGroup {
                ShareLink(item: self.shareLink)
                
                #if os(macOS)
                Button(action: {
                    Task {
                        await loadThread()
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
                .disabled(viewModel.state == .loading)
                #endif
            }
        }
    }
    
    private var shareLink: URL {
        ThreadView.dataProvider.getURL(for: boardId, threadId: threadId)
    }
    
    private var posts: [ThreadPost] {
        return viewModel.posts.filter { threadPost in
            if viewModel.filter == "" {
                return true
            } else if let subject = threadPost.post.subject, subject.localizedCaseInsensitiveContains(viewModel.filter) {
                return true
            } else if let body = threadPost.post.content, body.localizedCaseInsensitiveContains(viewModel.filter) {
                return true
            } else {
                return false
            }
        }
    }
    
    private func handleAssetAction(_ asset: Asset, _ action: AssetAction) {
        switch action {
        case .view:
            windowState.navigate(asset: asset)
        case .download:
            break
        }
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
    var filter: String = ""
    
    enum State: Equatable {
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
