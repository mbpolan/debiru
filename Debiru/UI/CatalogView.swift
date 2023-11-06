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
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        ScrollViewReader { scroll in
            VStack {
                List(threads, id: \.self) { thread in
                    HStack {
                        if let asset = thread.attachment {
                            VStack(alignment: .leading) {
                                AssetView(asset: asset,
                                          saveLocation: imageSaveLocation,
                                          spoilered: thread.spoileredImage,
                                          bounds: CGSize(width: 128.0, height: 128.0),
                                          onOpen: handleOpenImage)
                            }
                        }
                        
                        PostView(
                            thread.toPostContent(),
                            boardId: thread.boardId,
                            threadId: thread.id,
                            showReplies: false,
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
                
                // footer
                HStack(alignment: .firstTextBaseline) {
                    Spacer()
                    
                    NewPostCountView()
                    
                    RefreshTimerView(lastUpdate: $viewModel.lastUpdate)
                }
                .padding([.bottom, .leading, .trailing], 5)
            }
            .onNavigate { handleNavigation($0, proxy: scroll) }
            .onChange(of: appState.autoRefresh) { refresh in
                Task {
                    if refresh {
                        runRefreshTimer()
                    } else {
                        viewModel.refreshTask?.cancel()
                        viewModel.refreshTask = nil
                    }
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
                
                Toggle(isOn: $viewModel.filtersEnabled) {
                    Image(systemName: "text.badge.xmark")
                }
                .help("Toggle word filters")
                
                Button(action: handleReloadFromState) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.pendingThreads)
                .help("Refresh the catalog")
                
                SearchBarView(
                    expanded: $viewModel.searchExpanded,
                    search: $viewModel.search)
            }
        }
        .onRefreshView(perform: handleReloadFromState)
        .onOpenInBrowser {
            guard let board = getBoard(appState.currentItem),
                  let url = dataProvider.getURL(for: board) else { return }
            
            NSWorkspace.shared.open(url)
        }
        .onChange(of: appState.currentItem) { item in
            Task {
                await reload(from: item)
            }
        }
        .onChange(of: viewModel.filtersEnabled) { enabled in
            guard let board = getBoard(appState.currentItem) else { return }
            appState.boardFilterEnablement[board.id] = enabled
        }
        .task {
            await reloadFromState()
            updateFilterToggle()
            
            if appState.autoRefresh {
                runRefreshTimer()
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
        var data = viewModel.threads
        
        // apply filtering from the search bar
        if viewModel.searchExpanded && !viewModel.search.isEmpty {
            let query = viewModel.search.trimmingCharacters(in: .whitespaces)
            
            // take only threads that match the search query
            data = data.filter { $0.matchesFilter(query) }
        }
        
        // apply filtering for user provided word filters, if enabled
        if viewModel.filtersEnabled,
           let board = getBoard(appState.currentItem),
           let filters = appState.boardFilters[board.id] {
            
            // take only threads that do not match any of the individual filters
            data = data.filter { thread in
                return !filters.contains { thread.matchesFilter($0.filter) }
            }
        }
        
        return data
    }
    
    private func updateFilterToggle() {
        guard let board = getBoard(appState.currentItem) else { return }
        
        // are there filters on this board?
        viewModel.hasFilters = !(appState.boardFilters[board.id] ?? []).isEmpty
        
        // are filters manually disabled?
        viewModel.filtersEnabled = appState.boardFilterEnablement[board.id] ?? true
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
    
    private func handleReloadFromState() {
        Task {
            await reloadFromState()
        }
    }
    
    private func handleNavigation(_ destination: NavigateNotification, proxy: ScrollViewProxy) {
        switch destination {
        case .top:
            guard let first = threads.first else { return }
            proxy.scrollTo(first)
        case .down:
            guard let last = threads.last else { return }
            proxy.scrollTo(last)
        default:
            break
        }
    }
    
    private func handleOpenImage(_ asset: Asset) {
        if asset.fileType == .webm {
            ShowVideoNotification(asset: asset)
                .notify()
        } else {
            ShowImageNotification(asset: asset)
                .notify()
        }
    }
    
    private func handleShowThread(_ thread: Thread) {
        ThreadDestination
            .thread(thread)
            .notify()
    }
    
    private func handleLink(_ link: Link) {
        if let webLink = link as? WebLink {
            NSWorkspace.shared.open(webLink.url)
        }
    }
    
    private func runRefreshTimer() {
        viewModel.refreshTask = Task {
            await reloadFromState()
            try? await Task.sleep(nanoseconds: UInt64(refreshTimeout * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            runRefreshTimer()
        }
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
        
        PersistAppStateNotification().notify()
    }
    
    private func getBoard(_ item: ViewableItem?) -> Board? {
        switch item {
        case .board(let board):
            return board
        default:
            return nil
        }
    }
    
    private func reloadFromState() async {
        guard let board = getBoard(appState.currentItem) else { return }
        await reload(board)
    }
    
    private func reload(from item: ViewableItem?) async {
        guard let board = getBoard(item) else { return }
        await reload(board)
    }
    
    @MainActor
    private func reload(_ board: Board) async {
        self.viewModel.pendingThreads = true
        
        do {
            self.viewModel.threads = try await dataProvider.getCatalog(for: board)
            self.viewModel.lastUpdate = Date()
        } catch {
            print(error)
        }
        
        self.viewModel.pendingThreads = false
    }
}

// MARK: - View Model

class CatalogViewModel: ObservableObject {
    @Published var threads: [Thread] = []
    @Published var pendingThreads: Bool = false
    @Published var search: String = ""
    @Published var searchExpanded: Bool = false
    @Published var lastUpdate: Date = Date()
    @Published var refreshTask: Task<Void, Never>?
    @Published var hasFilters: Bool = false
    @Published var filtersEnabled: Bool = false
}

// MARK: - Preview

struct CatalogView_Previews: PreviewProvider {
    private static let board = Board(
        id: "f",
        title: "Foobar",
        description: "whatever",
        features: .init(supportsCode: false))
    
    static var previews: some View {
        CatalogView()
            .environmentObject(AppState(
                                currentItem: .board(board),
                                boards: [board],
                                openItems: []))
    }
}
