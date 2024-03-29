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
    @AppStorage(StorageKeys.showRelativeDates) private var showRelativeDates = UserDefaults.standard.showRelativeDates()
    
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
                   let post = viewModel.posts[targettedPostId] {
                    
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
                
                HStack {
                    Divider()
                }
                
                Toggle(isOn: $appState.threadDisplayTree) {
                    Image(systemName: "list.bullet.indent")
                }
                .help("Display replies as conversations")
                
                Toggle(isOn: $appState.threadDisplayList) {
                    Image(systemName: "list.bullet")
                }
                .help("Display replies as a flat list")
                
                HStack {
                    Divider()
                }
                
                Button(action: handleChangeOrder) {
                    Image(systemName: viewModel.order.rawValue)
                }
                .help("Toggle post ordering")
                
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
#if os(macOS)
            NSWorkspace.shared.open(url)
#elseif os(iOS)
            PFApplication.shared.open(url)
#endif
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
        .onChange(of: appState.threadDisplayTree) { toggled in
            appState.threadDisplayList = !toggled
            
        }
        .onChange(of: appState.threadDisplayList) { toggled in
            appState.threadDisplayTree = !toggled
            
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
        rootPost?.archived ?? false
    }
    
    private var rootPost: Post? {
        guard let firstPostId = self.viewModel.posts.keys.min() else { return nil }
        return self.viewModel.posts[firstPostId]
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
        if let root = viewModel.posts.values.first(where: { $0.replyToId == 0 }),
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
    
    private var posts: [PostModel] {
        var models: [PostModel]
        
        // depending on the display mode, use either the precomputed hierarchy model or create a new model
        // using the original post data
        if appState.threadDisplayTree {
            models = viewModel.data
        } else {
            models = viewModel.posts.map { PostModel(post: $1) }
        }
        
        if viewModel.searchExpanded && !viewModel.search.isEmpty {
            let query = viewModel.search.trimmingCharacters(in: .whitespaces)
            
            models = models.filter { model in
                guard let post = self.viewModel.posts[model.id] else { return false }
                
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
        
        return models.sorted { a, b in
            switch viewModel.order {
            case .descending:
                return a.id < b.id
            case .ascending:
                return a.id > b.id
            }
        }
    }
    
    private func makeList(_ scroll: ScrollViewProxy) -> some View {
        List(posts, children: \.children) { model in
            VStack {
                if let post = self.viewModel.posts[model.id] {
                    makePostRow(post, parentPostId: model.parentPostId, scroll: scroll)
                    
                    if shouldShowNewPostDividerAfter(model.id) {
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
            }
            .id(model.id)
        }
    }
    
    private func makePostRowStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(macOS)
        return HStack(content: content)
        #elseif os(iOS)
        return VStack(alignment: .leading, content: content)
        #endif
    }
    
    private func makePostRow(_ post: Post, parentPostId: Int?, scroll: ScrollViewProxy) -> some View {
        makePostRowStack() {
            if let asset = post.attachment {
                AssetView(asset: asset,
                          saveLocation: imageSaveLocation,
                          spoilered: post.spoileredImage,
                          bounds: CGSize(width: 128.0, height: 128.0),
                          onOpen: handleOpenImage)
            }

            // display post contents and other controls
            // we only show replies when in list display mode, since the tree display mode will automatically
            // group replies into threads
            PostView(
                post.toPostContent(),
                boardId: post.boardId,
                threadId: post.threadId,
                parentPostId: parentPostId,
                showReplies: appState.threadDisplayList,
                showRelativeDates: showRelativeDates,
                onActivate: { handleReplyTo(post)},
                onLink: { link in
                    handleLink(link, scrollProxy: scroll)
                })
                .padding(.leading, 10)

            Spacer()
        }
        // TODO: this is now broken with the new captcha system :(
//        .popover(isPresented: makeReplyPopoverPresented(post.id), arrowEdge: .leading) {
//            HStack {
//                if viewModel.replyPopoverType == .success {
//                    Image(systemName: "checkmark")
//                        .foregroundColor(.green)
//
//                    Text("Post successful!")
//                } else {
//                    Image(systemName: "exclamationmark.circle")
//                        .foregroundColor(.red)
//
//                    Text("Failed to submit post.")
//                }
//            }
//            .padding()
//        }
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
    
    private func makeReplyPopoverPresented(_ postId: Int) -> Binding<Bool> {
        return Binding<Bool>(
            get: { viewModel.replyPopoverPostId == postId },
            set: { _ in }
        )
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
    
    private func handleChangeOrder() {
        switch viewModel.order {
        case .descending:
            viewModel.order = .ascending
        case .ascending:
            viewModel.order = .descending
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
            guard let first = self.rootPost else { return }
            proxy.scrollTo(first)
        case .down:
            guard let last = posts.last,
                  let post = self.viewModel.posts[last.id] else { return }
            proxy.scrollTo(post)
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
            appState.watchedThreads.append(.initial(thread, posts: Array(self.viewModel.posts.values)))
            
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
           let targetPostModel = posts.first(where: { $0.id == postLink.postId }),
           let targetPost = self.viewModel.posts[targetPostModel.id] {
            
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
#if os(macOS)
            NSWorkspace.shared.open(webLink.url)
#elseif os(iOS)
            PFApplication.shared.open(webLink.url)
#endif
        }
    }
    
    private func handleUpdateLastPost() {
        // reset the new post count for the watched thread
        guard let watchedThread = getWatchedThread(),
              let index = appState.watchedThreads.firstIndex(of: watchedThread),
              let firstPostId = viewModel.posts.keys.min(),
              let lastPostId = viewModel.posts.keys.max(),
              let firstPost = viewModel.posts[firstPostId] else { return }
        
        appState.watchedThreads[index] = WatchedThread(
            thread: watchedThread.thread,
            lastPostId: lastPostId,
            currentLastPostId: lastPostId,
            totalNewPosts: 0,
            nowArchived: firstPost.archived,
            nowDeleted: watchedThread.nowDeleted)
    }
    
    private func shouldShowNewPostDividerAfter(_ postId: Int) -> Bool {
        guard let watchedThread = getWatchedThread() else { return false }
        
        // show dividers only if there are new posts after this one
        // we check this by comparing the max post id in the thread against this post's id
        return watchedThread.lastPostId == postId && (self.viewModel.posts.keys.max() ?? 0) > postId
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
    
    @MainActor
    private func reload(_ thread: Thread) async {
        self.viewModel.pendingPosts = true
        
        do {
            var posts = try await dataProvider.getPosts(for: thread)
            
            // process post contents depending on what features the board supports
            if let board = appState.boards.first(where: { $0.id == thread.boardId }) {
                posts = ContentProvider.instance.processPosts(posts, in: board)
            }
            
            // build a map of post ids to their models and count replies
            self.viewModel.posts = posts.reduce(into: [Int: Post]()) { memo, cur in
                memo[cur.id] = cur
            }
            
            // build a hierarchy of posts, starting from the top-level posts
            self.viewModel.data = posts
                .filter { $0.isRoot || $0.id == thread.id }
                .map { buildPostHierarchy(PostModel(post: $0), threadId: thread.id, posts: self.viewModel.posts)}
            
            self.viewModel.lastUpdate = Date()
            
            // pop the targetted post id from the app state
            self.viewModel.targettedPostId = appState.targettedPostId
            appState.targettedPostId = nil
        } catch {
            // FIXME: handle image 404
            print(error)
        }
    }
    
    private func buildPostHierarchy(_ model: PostModel, threadId: Int, posts: [Int: Post]) -> PostModel {
        // skip posts without children and the thread starter post itself
        guard let post = posts[model.id], model.id != threadId && post.replies.count > 0 else { return model }
        
        var children: [PostModel] = []
        for replyId in post.replies {
            if let reply = posts[replyId] {
                children.append(buildPostHierarchy(PostModel(post: reply, parentPostId: model.id), threadId: threadId, posts: posts))
            }
        }
        
        model.children = children
        return model
    }
}

// MARK: - View Model

fileprivate class PostModel: Identifiable {
    let id: Int
    let parentPostId: Int?
    var children: [PostModel]?
    
    init(post: Post, parentPostId: Int? = nil) {
        self.id = post.id
        self.parentPostId = parentPostId
    }
}

fileprivate class ThreadViewModel: ObservableObject {
    @Published var posts: [Int: Post] = [:]
    @Published var data: [PostModel] = []
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
    @Published var order: ThreadOrder = .descending
    var cancellables: Set<AnyCancellable> = Set()
    
    enum ReplyPopoverType: Identifiable {
        var id: Int { hashValue }
        
        case success
        case error
    }
    
    enum ThreadOrder: String {
        case ascending = "arrow.up"
        case descending = "arrow.down"
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
