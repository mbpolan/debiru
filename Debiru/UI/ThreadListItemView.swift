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
        let content = thread.subject ?? thread.content
        
        HStack(alignment: .center) {
            Text("/\(thread.boardId)/")
                .font(.title)
            
            Text(content?.removeHTML().unescapeHTML() ?? "")
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
                                tag: nil,
                                country: nil),
                            date: Date(),
                            subject: "<span class=\"quote\">&gt;what?</span>",
                            content: nil,
                            sticky: true,
                            closed: false,
                            spoileredImage: false,
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
