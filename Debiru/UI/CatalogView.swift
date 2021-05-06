//
//  CatalogView.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

import AppKit
import Combine
import SwiftUI

// MARK: - View

struct CatalogView: View {
    @AppStorage(StorageKeys.refreshTimeout) private var refreshTimeout = UserDefaults.standard.refreshTimeout()
    @AppStorage(StorageKeys.defaultImageLocation) private var defaultImageLocation = UserDefaults.standard.defaultImageLocation()
    @AppStorage(StorageKeys.groupImagesByBoard) private var groupImagesByBoard = UserDefaults.standard.groupImagesByBoard()
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: CatalogViewModel = CatalogViewModel()
    private let dataProvider: DataProvider
    private let refreshViewPublisher = NotificationCenter.default.publisher(for: .refreshView)
    private let openInBrowserPublisher = NotificationCenter.default.publisher(for: .openInBrowser)
    private let goToTopPublisher = NotificationCenter.default.publisher(for: .goToTop)
    private let goToBottomPublisher = NotificationCenter.default.publisher(for: .goToBottom)
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        ScrollViewReader { scroll in
            VStack {
                List(threads, id: \.self) { thread in
                    HStack {
                        if let asset = thread.attachment {
                            AssetView(asset: asset,
                                      saveLocation: imageSaveLocation,
                                      bounds: CGSize(width: 128.0, height: 128.0),
                                      onOpen: { handleOpenImage($0, asset: $1) })
                        }
                        
                        PostView(
                            thread.toPostContent(),
                            boardId: thread.boardId,
                            threadId: thread.id,
                            onActivate: { handleShowThread(thread) },
                            onLink: handleLink) {
                            
                            HStack(alignment: .firstTextBaseline) {
                                ThreadMetricsView(
                                    replies: thread.statistics.replies,
                                    images: thread.statistics.images,
                                    uniquePosters: thread.statistics.uniquePosters,
                                    bumpLimit: thread.statistics.bumpLimit,
                                    imageLimit: thread.statistics.imageLimit,
                                    page: thread.statistics.page,
                                    metrics: [.replies, .images, .page])
                                
                                Button(action: {
                                    handleToggleWatchedThread(thread)
                                }, label: {
                                    Image(systemName: isThreadWatched(thread)
                                            ? "star.fill"
                                            : "star")
                                })
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.leading, 5)
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                HStack(alignment: .firstTextBaseline) {
                    Spacer()
                    RefreshTimerView(lastUpdate: $viewModel.lastUpdate)
                }
                .padding([.bottom, .leading, .trailing], 5)
            }
            .onReceive(goToTopPublisher) { _ in
                if let first = threads.first {
                    scroll.scrollTo(first)
                }
            }
            .onReceive(goToBottomPublisher) { _ in
                if let last = threads.last {
                    scroll.scrollTo(last)
                }
            }
            .onChange(of: appState.autoRefresh) { refresh in
                if refresh {
                    startRefreshTimer()
                } else {
                    viewModel.refreshTimer?.invalidate()
                    viewModel.refreshTimer = nil
                }
            }
        }
        .navigationTitle(getNavigationTitle())
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: handleCloseCatalog) {
                    Image(systemName: "xmark")
                }
            }
            
            ToolbarItemGroup {
                Toggle("Auto-Refresh", isOn: $appState.autoRefresh)
                
                Button(action: reloadFromState) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.pendingThreads != nil)
                .help("Refresh the catalog")
                
                SearchBarView(
                    expanded: $viewModel.searchExpanded,
                    search: $viewModel.search)
            }
        }
        .onReceive(refreshViewPublisher) { _ in
            reloadFromState()
        }
        .onReceive(openInBrowserPublisher) { _ in
            guard let board = getBoard(appState.currentItem),
                  let url = dataProvider.getURL(for: board) else { return }
            
            NSWorkspace.shared.open(url)
        }
        .onChange(of: appState.currentItem) { item in
            reload(from: item)
        }
        .onAppear {
            reloadFromState()
            
            if appState.autoRefresh {
                startRefreshTimer()
            }
        }
    }
    
    private var imageSaveLocation: URL {
        if groupImagesByBoard,
           let board = getBoard(appState.currentItem) {
            return defaultImageLocation.appendingPathComponent("\(board.id)/")
        }
        
        return defaultImageLocation
    }
    
    private var threads: [Thread] {
        if viewModel.searchExpanded && !viewModel.search.isEmpty {
            let query = viewModel.search.trimmingCharacters(in: .whitespaces)
            
            return viewModel.threads.filter { thread in
                if let subject = thread.subject,
                   subject.localizedCaseInsensitiveContains(query) {
                    return true
                }
                
                if let content = thread.content,
                   content.localizedCaseInsensitiveContains(query) {
                    return true
                }
                
                return false
            }
        }
        
        return viewModel.threads
    }
    
    private func getNavigationTitle() -> String {
        if let board = getBoard(appState.currentItem) {
            return "/\(board.id)/"
        }
        
        return ""
    }
    
    private func handleCloseCatalog() {
        appState.currentItem = nil
    }
    
    private func handleOpenImage(_ data: Data, asset: Asset) {
        NotificationCenter.default.post(
            name: .showImage,
            object: DownloadedAsset(
                data: data,
                asset: asset))
    }
    
    private func handleShowThread(_ thread: Thread) {
        NotificationCenter.default.post(name: .showThread, object: thread)
    }
    
    private func handleLink(_ link: Link) {
        if let webLink = link as? WebLink {
            NSWorkspace.shared.open(webLink.url)
        }
    }
    
    private func startRefreshTimer() {
        viewModel.refreshTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(refreshTimeout),
            repeats: true) { _ in reloadFromState() }
    }
    
    private func isThreadWatched(_ thread: Thread) -> Bool {
        return appState.watchedThreads.contains(where: {
            return $0.thread.boardId == thread.boardId && $0.thread.id == thread.id
        })
    }
    
    private func handleToggleWatchedThread(_ thread: Thread) {
        if let index = appState.watchedThreads.firstIndex(where: {
            return $0.thread.boardId == thread.boardId && $0.thread.id == thread.id
        }) {
            
            appState.watchedThreads.remove(at: index)
        } else {
            appState.watchedThreads.append(.initial(thread))
        }
        
        NotificationCenter.default.post(name: .saveAppState, object: nil)
    }
    
    private func getBoard(_ item: ViewableItem?) -> Board? {
        switch item {
        case .board(let board):
            return board
        default:
            return nil
        }
    }
    
    private func reloadFromState() {
        guard let board = getBoard(appState.currentItem) else { return }
        reload(board)
    }
    
    private func reload(from item: ViewableItem?) {
        guard let board = getBoard(item) else { return }
        reload(board)
    }
    
    private func reload(_ board: Board) {
        viewModel.pendingThreads = dataProvider.getCatalog(for: board) { result in
            switch result {
            case .success(let threads):
                self.viewModel.threads = threads
                self.viewModel.lastUpdate = Date()
            case .failure(let error):
                print(error)
            }
            
            self.viewModel.pendingThreads = nil
        }
    }
}

// MARK: - View Model

class CatalogViewModel: ObservableObject {
    @Published var threads: [Thread] = []
    @Published var pendingThreads: AnyCancellable?
    @Published var search: String = ""
    @Published var searchExpanded: Bool = false
    @Published var lastUpdate: Date = Date()
    @Published var refreshTimer: Timer?
}

// MARK: - Preview

struct CatalogView_Previews: PreviewProvider {
    private static let board = Board(
        id: "f",
        title: "Foobar",
        description: "whatever")
    
    static var previews: some View {
        CatalogView()
            .environmentObject(AppState(
                                currentItem: .board(board),
                                boards: [board],
                                openItems: []))
    }
}
