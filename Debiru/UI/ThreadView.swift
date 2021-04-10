//
//  ThreadView.swift
//  Debiru
//
//  Created by Mike Polan on 3/23/21.
//

import Combine
import SwiftUI

// MARK: - View

struct ThreadView: View {
    @AppStorage(StorageKeys.refreshTimeout) private var refreshTimeout = UserDefaults.standard.refreshTimeout()
    @AppStorage(StorageKeys.defaultImageLocation) private var defaultImageLocation = UserDefaults.standard.defaultImageLocation()
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ThreadViewModel = ThreadViewModel()
    private let dataProvider: DataProvider
    private let refreshViewPublisher = NotificationCenter.default.publisher(for: .refreshView)
    private let openInBrowserPublisher = NotificationCenter.default.publisher(for: .openInBrowser)
    private let goToTopPublisher = NotificationCenter.default.publisher(for: .goToTop)
    private let goToBottomPublisher = NotificationCenter.default.publisher(for: .goToBottom)
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        let statistics = self.statistics
        
        ScrollViewReader { scroll in
            VStack {
                makeHeader()
                
                List(posts, id: \.self) { post in
                    HStack {
                        if let asset = post.attachment {
                            VStack(alignment: .leading) {
                                WebImage(asset,
                                         saveLocation: defaultImageLocation,
                                         bounds: CGSize(width: 128.0, height: 128.0),
                                         onOpen: handleOpenImage)
                                
                                Spacer()
                            }
                        }
                        
                        PostView(
                            post.toPostContent(),
                            boardId: post.boardId,
                            threadId: post.threadId,
                            onActivate: { },
                            onLink: { link in
                                handleLink(link, scrollProxy: scroll)
                            })
                            .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .id(post)
                }
                
                Divider()
                
                makeFooter(statistics)
            }
            .onReceive(goToTopPublisher) { _ in
                if let first = posts.first {
                    scroll.scrollTo(first)
                }
            }
            .onReceive(goToBottomPublisher) { _ in
                if let last = posts.last {
                    scroll.scrollTo(last)
                }
            }
        }
        .navigationTitle(getNavigationTitle())
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: handleBackToCatalog) {
                    Image(systemName: "chevron.backward")
                }
            }
            
            ToolbarItemGroup {
                Toggle("Auto-Refresh", isOn: $appState.autoRefresh)
                
                Button(action: handleToggleWatched) {
                    Image(systemName: isWatched ? "star.fill" : "star")
                }
                .help("Watch this thread")
                
                Button(action: reloadFromState) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.pendingPosts != nil)
                .help("Refresh the thread")
                
                SearchBarView(
                    expanded: $viewModel.searchExpanded,
                    search: $viewModel.search)
            }
        }
        .onReceive(refreshViewPublisher) { _ in
            reloadFromState()
        }
        .onReceive(openInBrowserPublisher) { _ in
            guard let thread = getThread(appState.currentItem),
                  let url = dataProvider.getURL(for: thread) else { return }
            
            NSWorkspace.shared.open(url)
        }
        .onChange(of: appState.currentItem) { item in
            reload(from: item)
        }
        .onChange(of: appState.autoRefresh) { refresh in
            if refresh {
                startRefreshTimer()
            } else {
                viewModel.refreshTimer?.invalidate()
                viewModel.refreshTimer = nil
            }
        }
        .onAppear {
            reloadFromState()
            
            if appState.autoRefresh {
                startRefreshTimer()
            }
        }
    }
    
    private var isWatched: Bool {
        guard let thread = getThread(appState.currentItem) else { return false }
        
        return appState.watchedThreads.contains {
            return $0.thread.boardId == thread.boardId && $0.thread.id == thread.id
        }
    }
    
    private var statistics: ThreadViewModel.Statistics {
        // use the most up to date original post data
        // otherwise, use the thread-level data we have on hand
        if let root = viewModel.posts.first(where: { $0.isRoot }),
           let stats = root.threadStatistics {
            return ThreadViewModel.Statistics(
                replies: stats.replies,
                images: stats.images,
                uniquePosters: stats.uniquePosters,
                bumpLimit: stats.bumpLimit,
                imageLimit: stats.imageLimit)
            
        } else if let thread = getThread(appState.currentItem) {
            return ThreadViewModel.Statistics(
                replies: thread.statistics.replies,
                images: thread.statistics.images,
                uniquePosters: thread.statistics.uniquePosters,
                bumpLimit: thread.statistics.bumpLimit,
                imageLimit: thread.statistics.imageLimit)
        }
        
        // nothing to show!
        return .empty
    }
    
    private var posts: [Post] {
        if viewModel.searchExpanded && !viewModel.search.isEmpty {
            let query = viewModel.search.trimmingCharacters(in: .whitespaces)
            
            return viewModel.posts.filter { post in
                if let subject = post.subject,
                   subject.localizedCaseInsensitiveContains(query) {
                    return true
                }
                
                if let content = post.content,
                   content.localizedCaseInsensitiveContains(query) {
                    return true
                }
                
                return false
            }
        }
        
        return viewModel.posts
    }
    
    private func makeHeader() -> some View {
        VStack {
            if let op = posts.first, op.archived {
                HStack(alignment: .firstTextBaseline) {
                    Spacer()
                    
                    Image(systemName: "exclamationmark.triangle")
                    Text("This thread has been archived")
                        .font(.callout)
                    
                    Spacer()
                }
                .padding()
                
                Divider()
            }
        }
    }
    
    private func makeFooter(_ statistics: ThreadViewModel.Statistics) -> some View {
        HStack(alignment: .firstTextBaseline) {
            ThreadMetricsView(
                replies: statistics.replies,
                images: statistics.images,
                uniquePosters: statistics.uniquePosters,
                bumpLimit: statistics.bumpLimit,
                imageLimit: statistics.imageLimit,
                page: nil,
                metrics: [.images, .replies, .uniquePosters])
            
            Spacer()
            
            RefreshTimerView(lastUpdate: $viewModel.lastUpdate)
        }
        .padding([.bottom, .leading, .trailing], 5)
    }
    
    private func handleOpenImage(_ data: Data) {
        NotificationCenter.default.post(name: .showImage, object: data)
    }
    
    private func handleBackToCatalog() {
        if let board = getParentBoard(appState.currentItem) {
            NotificationCenter.default.post(name: .showBoard, object: board)
        }
    }
    
    private func handleToggleWatched() {
        guard let thread = getThread(appState.currentItem) else { return }
        
        if isWatched,
           let index = appState.watchedThreads.firstIndex(where: {
            return $0.thread.boardId == thread.boardId && $0.thread.id == thread.id
           }) {
            
            appState.watchedThreads.remove(at: index)
        } else {
            appState.watchedThreads.append(.initial(thread, posts: posts))
        }
    }
    
    private func handleLink(_ link: Link, scrollProxy: ScrollViewProxy) {
        // if this link refers to a post in this thread, we can scroll to it right away
        if let thread = getThread(appState.currentItem),
           let postLink = link as? PostLink,
           postLink.threadId == thread.id,
           let targetPost = posts.first(where: { $0.id == postLink.postId }) {
            
            // this must be the same post object we used in the list
            withAnimation {
                scrollProxy.scrollTo(targetPost)
            }
        }
    }
    
    private func getNavigationTitle() -> String {
        if let thread = getThread(appState.currentItem) {
            return "/\(thread.boardId)/ - \(thread.id)"
        }
        
        return ""
    }
    
    private func getParentBoard(_ item: ViewableItem?) -> Board? {
        switch item {
        case .thread(let board, _):
            return board
        default:
            return nil
        }
    }
    
    private func getThread(_ item: ViewableItem?) -> Thread? {
        switch item {
        case .thread(_, let thread):
            return thread
        default:
            return nil
        }
    }
    
    private func startRefreshTimer() {
        viewModel.refreshTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(refreshTimeout),
            repeats: true) { _ in reloadFromState() }
    }
    
    private func reloadFromState() {
        guard let thread = getThread(appState.currentItem) else { return }
        reload(thread)
    }
    
    private func reload(from item: ViewableItem?) {
        guard let thread = getThread(item) else { return }
        reload(thread)
    }
    
    private func reload(_ thread: Thread) {
        viewModel.pendingPosts = dataProvider.getPosts(for: thread) { result in
            switch result {
            case .success(let posts):
                self.viewModel.posts = posts
                self.viewModel.lastUpdate = Date()
            case .failure(let error):
                print(error)
            }
            
            self.viewModel.pendingPosts = nil
        }
    }
}

// MARK: - View Model

class ThreadViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var pendingPosts: AnyCancellable?
    @Published var search: String = ""
    @Published var searchExpanded: Bool = false
    @Published var lastUpdate: Date = Date()
    @Published var refreshTimer: Timer?
    
    struct Statistics {
        let replies: Int?
        let images: Int?
        let uniquePosters: Int?
        let bumpLimit: Bool
        let imageLimit: Bool
        
        static var empty: Statistics {
            return Statistics(
                replies: nil,
                images: nil,
                uniquePosters: nil,
                bumpLimit: false,
                imageLimit: false)
        }
    }
}

// MARK: - Preview

struct ThreadView_Previews: PreviewProvider {
    private static let thread = Thread(
        id: 123,
        boardId: "/foo",
        author: User(
            name: "Anonymous",
            tripCode: nil,
            isSecure: false),
        date: Date(),
        subject: "foo",
        content: nil,
        sticky: false,
        closed: false,
        attachment: nil,
        statistics: ThreadStatistics(
            replies: 1,
            images: 1,
            uniquePosters: 1,
            bumpLimit: false,
            imageLimit: false,
            page: 0))
    
    static var previews: some View {
        ThreadView()
            .environmentObject(AppState(
                                currentItem: .thread(nil, thread),
                                boards: [],
                                openItems: []))
    }
}
