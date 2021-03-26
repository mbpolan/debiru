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
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ThreadViewModel = ThreadViewModel()
    private let dataProvider: DataProvider
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        List(posts, id: \.self) { post in
            HStack {
                if let asset = post.attachment {
                    WebImage(asset,
                             bounds: CGSize(width: 128.0, height: 128.0))
                }
                
                PostListItemView(post)
                
                Spacer()
            }
        }
        .navigationTitle(getNavigationTitle())
        .toolbar {
            SearchBarView(
                expanded: $viewModel.searchExpanded,
                search: $viewModel.search)
        }
        .onChange(of: appState.currentItem) { item in
            reload(from: item)
        }
        .onAppear {
            reloadFromState()
        }
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
    
    private func getNavigationTitle() -> String {
        if let thread = getThread(appState.currentItem) {
            return "/\(thread.boardId)/ - \(thread.id)"
        }
        
        return ""
    }
    
    private func getThread(_ item: ViewableItem?) -> Thread? {
        switch item {
        case .thread(let thread):
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
}

// MARK: - PostListItemView

fileprivate struct PostListItemView: View {
    private let post: Post
    
    init(_ post: Post) {
        self.post = post
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(post.subject ?? "")
                .font(.title)
            
            Text("\(post.id)").bold() +
                Text("Posted by ") +
                Text(post.author).bold() +
                Text(" on \(PostListItemView.formatter.string(from: post.date))")
            
            RichTextView(html: post.content ?? "")
        }
    }
    
    private static var formatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        
        return dateFormatter
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
        attachment: nil)
    
    static var previews: some View {
        ThreadView()
            .environmentObject(AppState(
                                currentItem: .thread(thread),
                                boards: [],
                                openItems: []))
    }
}
