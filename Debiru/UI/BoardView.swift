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
    @AppStorage(StorageKeys.defaultImageLocation) private var imageSaveLocation: URL = Settings.defaultImageLocation
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
                List(self.threads) { post in
                    PostView(post: post,
                             onTapGesture: { handleGoToThread(post) },
                             onAssetAction: handleAssetAction)
                    .postViewListItem()
                }
            }
        }
        .navigationTitle(viewModel.board?.title ?? "")
        .searchable(text: $viewModel.filter)
        .postList()
        .task(id: boardId) {
            await loadBoard()
        }
        .refreshable {
            await refresh()
        }
        #if os(macOS)
        .toolbar {
            ToolbarItemGroup {
                Button(action: {
                    Task {
                        await loadBoard()
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
                .disabled(viewModel.state == .loading)
            }
        }
        #endif
    }
    
    private var threads: [Post] {
        return viewModel.threads.filter { post in
            if viewModel.filter == "" {
                return true
            } else if let subject = post.subject, subject.localizedCaseInsensitiveContains(viewModel.filter) {
                return true
            } else if let body = post.content, body.localizedCaseInsensitiveContains(viewModel.filter) {
                return true
            } else {
                return false
            }
        }
    }
    
    private func handleGoToThread(_ post: Post) {
        windowState.navigate(boardId: boardId, threadId: post.threadId)
    }
    
    private func handleAssetAction(_ asset: Asset, _ action: AssetAction) {
        switch action {
        case .view:
            windowState.navigate(asset: asset)
        case .download:
            DownloadManager.instance().addDownload(asset: asset, to: imageSaveLocation
                .appendingPathComponent(boardId, conformingTo: .fileURL)
                .appendingPathComponent("\(asset.filename)\(asset.extension)", conformingTo: .fileURL))
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
    var filter: String = ""
    
    enum State: Equatable {
        case loading
        case ready
        case error(_ message: String)
    }
}

// MARK: - Previews

#Preview {
    BoardView(boardId: "a")
}
