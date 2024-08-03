//
//  SavedThreadsView.swift
//  Debiru
//
//  Created by Mike Polan on 7/31/24.
//

import SwiftUI

// MARK: - View

/// A view that displays a list of threads saved by the user.
struct SavedThreadsView: View {
    @Environment(AppState.self) var appState
    
    var body: some View {
        List(appState.savedThreads) { item in
            PostView(post: item.original)
                .postViewListItem(item.original)
        }
        .navigationTitle("Saved Threads")
    }
}

// MARK: - Previews

#Preview {
    SavedThreadsView()
        .environment(AppState(boards: [], downloads: [], savedThreads: [
            SavedThread(original: Post(id: 123456,
                                       boardId: "a",
                                       threadId: 123456,
                                       isRoot: true,
                                       author: .init(name: "Anonymous",
                                                     tripCode: nil,
                                                     isSecure: false,
                                                     tag: nil,
                                                     country: nil),
                                       date: .now,
                                       replyToId: nil,
                                       subject: "Whatever lol, some title or other",
                                       content: nil,
                                       body: nil,
                                       sticky: false,
                                       closed: false,
                                       spoileredImage: false,
                                       attachment: nil,
                                       threadStatistics: .init(replies: 0,
                                                               images: 0,
                                                               uniquePosters: 0,
                                                               bumpLimit: false,
                                                               imageLimit: false,
                                                               page: 1),
                                       archived: false,
                                       archivedDate: nil,
                                       replies: []),
                        created: .now,
                        localURL: URL(string: "https://google.pl")!),
            SavedThread(original: Post(id: 8888888,
                                       boardId: "g",
                                       threadId: 222222,
                                       isRoot: true,
                                       author: .init(name: "Anonymous",
                                                     tripCode: nil,
                                                     isSecure: false,
                                                     tag: nil,
                                                     country: nil),
                                       date: .now,
                                       replyToId: nil,
                                       subject: nil,
                                       content: nil,
                                       body: nil,
                                       sticky: false,
                                       closed: false,
                                       spoileredImage: false,
                                       attachment: nil,
                                       threadStatistics: .init(replies: 0,
                                                               images: 0,
                                                               uniquePosters: 0,
                                                               bumpLimit: false,
                                                               imageLimit: false,
                                                               page: 1),
                                       archived: false,
                                       archivedDate: nil,
                                       replies: []),
                        created: .now,
                        localURL: URL(string: "https://google.pl")!),
        ]))
}
