//
//  ThreadListItemView.swift
//  Debiru
//
//  Created by Mike Polan on 4/8/21.
//

import SwiftUI

// MARK: - View

struct ThreadListItemView: View {
    private let thread: Thread
    
    init(_ thread: Thread) {
        self.thread = thread
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text("/\(thread.boardId)/")
                .font(.title)
            
            Text(thread.subject ?? thread.content ?? "")
        }
    }
}

// MARK: - Preview

struct ThreadListItemView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListItemView(Thread(
                            id: 123,
                            boardId: "f",
                            author: User(
                                name: nil,
                                tripCode: nil,
                                isSecure: false,
                                tag: nil),
                            date: Date(),
                            subject: nil,
                            content: nil,
                            sticky: true,
                            closed: false,
                            attachment: nil,
                            statistics: ThreadStatistics(
                                replies: 0,
                                images: 0,
                                uniquePosters: 0,
                                bumpLimit: false,
                                imageLimit: false,
                                page: nil)))
    }
}
