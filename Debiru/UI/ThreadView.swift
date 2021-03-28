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
    // a default number formatter for human readable statistics
    private static let numberFormatter: NumberFormatter = {
       let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    @AppStorage(StorageKeys.defaultImageLocation) private var defaultImageLocation = UserDefaults.standard.defaultImageLocation()
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ThreadViewModel = ThreadViewModel()
    private let dataProvider: DataProvider
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        let statistics = self.statistics
        
        VStack {
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
                        threadId: post.threadId)
                    
                    Spacer()
                }
            }
            
            Divider()
            
            makeFooter(statistics)
        }
        .navigationTitle(getNavigationTitle())
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: handleBackToCatalog) {
                    Image(systemName: "chevron.backward")
                }
            }
            
            ToolbarItemGroup {
                SearchBarView(
                    expanded: $viewModel.searchExpanded,
                    search: $viewModel.search)
            }
        }
        .onChange(of: appState.currentItem) { item in
            reload(from: item)
        }
        .onAppear {
            reloadFromState()
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
                uniquePosters: stats.uniquePosters)
            
        } else if let thread = getThread(appState.currentItem) {
            return ThreadViewModel.Statistics(
                replies: thread.statistics.replies,
                images: thread.statistics.images,
                uniquePosters: thread.statistics.uniquePosters)
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
    
    private func makeNumberText(_ number: Int?) -> Text {
        var text: String?
        if let number = number {
            text = ThreadView.numberFormatter.string(from: NSNumber(value: number))
        }
        
        return Text(text ?? "?")
    }
    
    private func makeFooter(_ statistics: ThreadViewModel.Statistics) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Group {
                Image(systemName: "message.fill")
                makeNumberText(statistics.replies)
            }
            .help("Number of replies to original post")
            
            Group {
                Image(systemName: "photo.fill")
                makeNumberText(statistics.images)
            }
            .help("Number of replies containing images")
            
            Group {
                Image(systemName: "person.2.fill")
                makeNumberText(statistics.uniquePosters)
            }
            .help("Number of unique posters in this thread")
                
            Spacer()
        }
        .padding(.bottom, 5)
        .padding(.leading, 5)
    }
    
    private func handleOpenImage(_ data: Data) {
        NotificationCenter.default.post(name: .showImage, object: data)
    }
    
    private func handleBackToCatalog() {
        if let board = getParentBoard(appState.currentItem) {
            NotificationCenter.default.post(name: .showBoard, object: board)
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
    
    struct Statistics {
        let replies: Int?
        let images: Int?
        let uniquePosters: Int?
        
        static var empty: Statistics {
            return Statistics(
                replies: nil,
                images: nil,
                uniquePosters: nil)
        }
    }
}

// MARK: - Preview

struct ThreadView_Previews: PreviewProvider {
    private static let thread = Thread(
        id: 123,
        boardId: "/foo",
        poster: "",
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
            imageLimit: false))
    
    static var previews: some View {
        ThreadView()
            .environmentObject(AppState(
                                currentItem: .thread(nil, thread),
                                boards: [],
                                openItems: []))
    }
}
