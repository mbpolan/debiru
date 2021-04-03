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
    @AppStorage(StorageKeys.defaultImageLocation) private var defaultImageLocation = UserDefaults.standard.defaultImageLocation()
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: CatalogViewModel = CatalogViewModel()
    private let dataProvider: DataProvider
    private let refreshViewPublisher = NotificationCenter.default.publisher(for: .refreshView)
    private let openInBrowserPublisher = NotificationCenter.default.publisher(for: .openInBrowser)
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        VStack {
            List(threads, id: \.self) { thread in
                HStack {
                    if let asset = thread.attachment {
                        VStack(alignment: .leading) {
                            WebImage(asset,
                                     saveLocation: defaultImageLocation,
                                     bounds: CGSize(width: 128.0, height: 128.0),
                                     onOpen: handleOpenImage)
                            
                            Spacer()
                        }
                    }
                    
                    PostView(
                        thread.toPostContent(),
                        boardId: thread.boardId,
                        threadId: thread.id,
                        onActivate: { handleShowThread(thread) },
                        onLink: handleLink) {
                        
                        ThreadMetricsView(
                            replies: thread.statistics.replies,
                            images: thread.statistics.images,
                            uniquePosters: thread.statistics.uniquePosters,
                            bumpLimit: thread.statistics.bumpLimit,
                            imageLimit: thread.statistics.imageLimit,
                            page: thread.statistics.page,
                            metrics: [.replies, .images, .page])
                            .padding(.leading, 5)
                    }
                    
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
        .navigationTitle(getNavigationTitle())
        .toolbar {
            ToolbarItemGroup {
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
        }
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
    
    private func handleOpenImage(_ data: Data) {
        NotificationCenter.default.post(name: .showImage, object: data)
    }
    
    private func handleShowThread(_ thread: Thread) {
        NotificationCenter.default.post(name: .showThread, object: thread)
    }
    
    private func handleLink(_ link: Link) {
        // TODO
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
