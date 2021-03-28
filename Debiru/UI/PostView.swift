//
//  PostView.swift
//  Debiru
//
//  Created by Mike Polan on 3/27/21.
//

import SwiftUI

// MARK: - View

struct PostView: View {
    private let content: PostContent
    private let boardId: String
    private let threadId: Int
    
    init(_ content: PostContent, boardId: String, threadId: Int) {
        self.content = content
        self.boardId = boardId
        self.threadId = threadId
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(content.subject ?? "")
                .font(.title)
            
            HStack(alignment: .firstTextBaseline, spacing: 3.0) {
                if content.sticky {
                    Image(systemName: "pin.fill")
                        .foregroundColor(Color(NSColor.systemGreen))
                        .help("This thread is stickied")
                }
                
                if content.closed {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Color(NSColor.systemRed))
                        .help("This thread is locked")
                }
                
                Text("#\(String(content.id)) ").bold() +
                    Text("Posted by ") +
                    Text(content.author).bold() +
                    Text(" on \(PostView.formatter.string(from: content.date))")
            }
            
            RichTextView(
                content.content ?? "",
                boardId: boardId,
                threadId: threadId)
            
            Spacer()
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

// MARK: - PostContent

struct PostContent {
    let id: Int
    let author: String
    let date: Date
    let subject: String?
    let content: String?
    let attachment: Asset?
    let sticky: Bool
    let closed: Bool
    let archived: Bool
    let archivedDate: Date?
}

// MARK: - Thread Extensions

extension Thread {
    func toPostContent() -> PostContent {
        return PostContent(
            id: self.id,
            author: self.poster,
            date: self.date,
            subject: self.subject,
            content: self.content,
            attachment: self.attachment,
            sticky: self.sticky,
            closed: self.closed,
            archived: false,
            archivedDate: nil)
    }
}


// MARK: - Post Extensions

extension Post {
    func toPostContent() -> PostContent {
        return PostContent(
            id: self.id,
            author: self.author,
            date: self.date,
            subject: self.subject,
            content: self.content,
            attachment: self.attachment,
            sticky: self.sticky,
            closed: self.closed,
            archived: self.archived,
            archivedDate: self.archivedDate)
    }
}

// MARK: - Preview

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(PostContent(
                    id: 123,
                    author: "Anonymous",
                    date: Date(),
                    subject: "Something",
                    content: "Ain't this cool?",
                    attachment: nil,
                    sticky: false,
                    closed: false,
                    archived: false,
                    archivedDate: nil),
                 boardId: "f",
                 threadId: 321)
    }
}
