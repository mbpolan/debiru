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
    @AppStorage(StorageKeys.autoWatchReplied) private var autoWatchReplied = UserDefaults.standard.autoWatchReplied()
    @AppStorage(StorageKeys.refreshTimeout) private var refreshTimeout = UserDefaults.standard.refreshTimeout()
    @AppStorage(StorageKeys.defaultImageLocation) private var defaultImageLocation = UserDefaults.standard.defaultImageLocation()
    @AppStorage(StorageKeys.groupImagesByBoard) private var groupImagesByBoard = UserDefaults.standard.groupImagesByBoard()
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ThreadViewModel = ThreadViewModel()
    private let dataProvider: DataProvider
    private var bag: Set<AnyCancellable> = Set()
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        ScrollViewReader { scroll in
            VStack {
                makeHeader()
                
                if viewModel.deleted {
                    ErrorView(type: .threadDeleted)
                } else {
                    makeList(scroll)
                }
                
                Divider()
                
                makeFooter()
            }
            .onNavigate { handleNavigation($0, proxy: scroll) }
            .onChange(of: viewModel.targettedPostId) { targettedPostId in
                if let targettedPostId = targettedPostId,
                   let post = viewModel.posts.first(where: { $0.id == targettedPostId }) {
                    
                    scroll.scrollTo(post)
                    viewModel.targettedPostId = nil
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
                
                Button(action: handleReloadFromState) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.pendingPosts)
                .help("Refresh the thread")
                
                SearchBarView(
                    expanded: $viewModel.searchExpanded,
                    search: $viewModel.search)
            }
        }
        .onRefreshView(perform: handleReloadFromState)
        .onOpenInBrowser {
            guard let thread = getThread(appState.currentItem),
                  let url = dataProvider.getURL(for: thread) else { return }
            
            NSWorkspace.shared.open(url)
        }
        .onChange(of: appState.currentItem) { item in
            Task {
                await reload(from: item)
            }
        }
        .onChange(of: appState.autoRefresh) { refresh in
            if refresh {
                runRefreshTimer()
            } else {
                viewModel.refreshTask?.cancel()
                viewModel.refreshTask = nil
            }
        }
        .sheet(item: $viewModel.replyToPost, onDismiss: handleHideReplySheet) { post in
            // replies are always against the original post
            let replyTo = post.replyToId ?? post.id
            
            if let board = getParentBoard(appState.currentItem) {
                PostEditorView(
                    board: board,
                    replyTo: replyTo,
                    initialContent: viewModel.initialReplyToContent,
                    onDismiss: handleHideReplySheet,
                    onComplete: handlePostComplete)
            }
        }
        .task {
            await reloadFromState()
            
            if appState.autoRefresh {
                runRefreshTimer()
            }
        }
    }
    
    private var isWatched: Bool {
        getWatchedThread() != nil
    }
    
    private var isArchived: Bool {
        posts.first?.archived ?? false
    }
    
    private var imageSaveLocation: URL {
        if groupImagesByBoard,
           let thread = getThread(appState.currentItem) {
            return defaultImageLocation.appendingPathComponent("\(thread.boardId)/")
        }
        
        return defaultImageLocation
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
    
    private func makeList(_ scroll: ScrollViewProxy) -> some View {
        List(posts, id: \.self) { post in
            VStack {
                HStack {
                    if let asset = post.attachment {
                        AssetView(asset: asset,
                                  saveLocation: imageSaveLocation,
                                  spoilered: post.spoileredImage,
                                  bounds: CGSize(width: 128.0, height: 128.0),
                                  onOpen: { handleOpenImage($0, asset: $1) })
                    }
                    
                    PostView(
                        post.toPostContent(),
                        boardId: post.boardId,
                        threadId: post.threadId,
                        onActivate: { handleReplyTo(post)} ,
                        onLink: { link in
                            handleLink(link, scrollProxy: scroll)
                        })
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .popover(isPresented: makeReplyPopoverPresented(post), arrowEdge: .leading) {
                    HStack {
                        if viewModel.replyPopoverType == .success {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                            
                            Text("Post successful!")
                        } else {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.red)
                            
                            Text("Failed to submit post.")
                        }
                    }
                    .padding()
                }
                
                if shouldShowNewPostDividerAfter(post) {
                    TextDivider("New Posts", color: .red)
                        .onAppear {
                            // schedule an update to reset the new post marker
                            Timer.scheduledTimer(
                                withTimeInterval: TimeInterval(5),
                                repeats: false,
                                block: { _ in handleUpdateLastPost() })
                        }
                }
            }
            .id(post)
        }
    }
    
    private func makeHeader() -> some View {
        VStack {
            if isArchived {
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
    
    private func makeFooter() -> some View {
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
            
            NewPostCountView()
            
            RefreshTimerView(lastUpdate: $viewModel.lastUpdate)
        }
        .padding([.bottom, .leading, .trailing], 5)
    }
    
    private func makeReplyPopoverPresented(_ post: Post) -> Binding<Bool> {
        return Binding<Bool>(
            get: { viewModel.replyPopoverPostId == post.id },
            set: { _ in }
        )
    }
    
    private func handleOpenImage(_ data: Data?, asset: Asset) {
        if asset.fileType == .webm {
            ShowVideoNotification(asset: asset)
                .notify()
        } else if let data = data {
            ShowImageNotification(
                asset: DownloadedAsset(
                    data: data,
                    asset: asset))
                .notify()
        }
    }
    
    private func handleReloadFromState() {
        Task {
            await reloadFromState()
        }
    }
    
    private func handleNavigation(_ destination: NavigateNotification, proxy: ScrollViewProxy) {
        // do not perform navigation if the post editor is open
        if viewModel.replyToPost != nil {
            return
        }
        
        switch destination {
        case .back:
            handleBackToCatalog()
        case .top:
            guard let first = posts.first else { return }
            proxy.scrollTo(first)
        case .down:
            guard let last = posts.last else { return }
            proxy.scrollTo(last)
        }
    }
    
    private func handleBackToCatalog() {
        if let thread = getThread(appState.currentItem),
           let board = appState.boards.first(where: { $0.id == thread.boardId }) {
            
            BoardDestination(board: board, filter: nil)
                .notify()
        }
    }
    
    private func addThreadToWatched() {
        guard let thread = getThread(appState.currentItem) else { return }
        
        if !isWatched {
            appState.watchedThreads.append(.initial(thread, posts: posts))
            
            PersistAppStateNotification().notify()
        }
    }
    
    private func removeThreadFromWatched() {
        guard let thread = getThread(appState.currentItem) else { return }
        
        if isWatched,
           let index = appState.watchedThreads.firstIndex(where: {
            return $0.thread.boardId == thread.boardId && $0.thread.id == thread.id
           }) {
            
            appState.watchedThreads.remove(at: index)
            PersistAppStateNotification().notify()
        }
    }
    
    private func handleToggleWatched() {
        if isWatched {
           removeThreadFromWatched()
        } else {
            addThreadToWatched()
        }
    }
    
    private func handleReplyTo(_ post: Post) {
        if isArchived {
            return
        }
        
        viewModel.replyToPost = post
        
        // prepare a default post template as a response
        viewModel.initialReplyToContent = ">>\(post.id)\n"
    }
    
    private func handlePostComplete() {
        // show a popover to provide visual feedback
        viewModel.replyPopoverType = .success
        viewModel.replyPopoverPostId = viewModel.replyToPost?.id
        
        handleHideReplySheet()
        
        // watch the thread if needed
        if autoWatchReplied {
            addThreadToWatched()
        }
        
        // schedule the popover automatically hiding after a few seconds,
        // and refresh the thread afterwards
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Task {
                viewModel.replyPopoverType = nil
                viewModel.replyPopoverPostId = nil
                
                await reloadFromState()
            }
        }
    }
    
    private func handleHideReplySheet() {
        viewModel.replyToPost = nil
        viewModel.initialReplyToContent = nil
    }
    
    private func handleLink(_ link: Link, scrollProxy: ScrollViewProxy) {
        // if this link refers to a post in this thread, we can scroll to it right away
        if let postLink = link as? PostLink,
           let thread = getThread(appState.currentItem),
           postLink.threadId == thread.id,
           let targetPost = posts.first(where: { $0.id == postLink.postId }) {
            
            // this must be the same post object we used in the list
            withAnimation {
                scrollProxy.scrollTo(targetPost)
            }
        } else if let boardLink = link as? BoardLink,
                  let board = appState.boards.first(where: { $0.id == boardLink.boardId }) {
            
            BoardDestination(
                board: board,
                filter: boardLink.filter)
                .notify()
        } else if let webLink = link as? WebLink {
            NSWorkspace.shared.open(webLink.url)
        }
    }
    
    private func handleUpdateLastPost() {
        // reset the new post count for the watched thread
        guard let watchedThread = getWatchedThread(),
              let index = appState.watchedThreads.firstIndex(of: watchedThread),
              let firstPost = viewModel.posts.first,
              let lastPost = viewModel.posts.last else { return }
        
        appState.watchedThreads[index] = WatchedThread(
            thread: watchedThread.thread,
            lastPostId: lastPost.id,
            currentLastPostId: lastPost.id,
            totalNewPosts: 0,
            nowArchived: firstPost.archived,
            nowDeleted: watchedThread.nowDeleted)
    }
    
    private func shouldShowNewPostDividerAfter(_ post: Post) -> Bool {
        guard let watchedThread = getWatchedThread(),
              let postIndex = viewModel.posts.firstIndex(of: post) else { return false }
        
        // show dividers only if there are new posts after this one
        return watchedThread.lastPostId == post.id &&
            postIndex < viewModel.posts.endIndex - 1
    }
    
    private func getNavigationTitle() -> String {
        if let thread = getThread(appState.currentItem) {
            return "/\(thread.boardId)/ - \(thread.id)"
        }
        
        return ""
    }
    
    private func getWatchedThread() -> WatchedThread? {
        guard let thread = getThread(appState.currentItem) else { return nil }
        
        return appState.watchedThreads.first {
            return $0.thread.boardId == thread.boardId && $0.thread.id == thread.id
        }
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
    
    private func runRefreshTimer() {
        viewModel.refreshTask = Task {
            await reloadFromState()
            try? await Task.sleep(nanoseconds: UInt64(refreshTimeout * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            runRefreshTimer()
        }
    }
    
    private func reloadFromState() async {
        guard let thread = getThread(appState.currentItem) else { return }
        await reload(thread)
    }
    
    private func reload(from item: ViewableItem?) async {
        guard let thread = getThread(item) else { return }
        await reload(thread)
    }
    
    private func reload(_ thread: Thread) async {
        self.viewModel.pendingPosts = true
        
        do {
            self.viewModel.posts = try await dataProvider.getPosts(for: thread)
            self.viewModel.lastUpdate = Date()
            
            // pop the targetted post id from the app state
            self.viewModel.targettedPostId = appState.targettedPostId
            appState.targettedPostId = nil
        } catch {
            // FIXME: handle image 404
            print(error)
        }
    }
}

// MARK: - View Model

class ThreadViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var pendingPosts: Bool = false
    @Published var search: String = ""
    @Published var searchExpanded: Bool = false
    @Published var lastUpdate: Date = Date()
    @Published var refreshTask: Task<Void, Never>?
    @Published var targettedPostId: Int?
    @Published var replyToPost: Post?
    @Published var initialReplyToContent: String?
    @Published var replyPopoverPostId: Int?
    @Published var replyPopoverType: ReplyPopoverType?
    @Published var deleted: Bool = false
    var cancellables: Set<AnyCancellable> = Set()
    
    enum ReplyPopoverType: Identifiable {
        var id: Int { hashValue }
        
        case success
        case error
    }
    
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
            isSecure: false,
            tag: nil,
            country: nil),
        date: Date(),
        subject: "foo",
        content: nil,
        sticky: false,
        closed: false,
        spoileredImage: false,
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
