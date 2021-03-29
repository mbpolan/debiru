//
//  PostView.swift
//  Debiru
//
//  Created by Mike Polan on 3/27/21.
//

import SwiftUI

// MARK: - View

struct PostView<T>: View where T: View {
    private let content: PostContent
    private let boardId: String
    private let threadId: Int
    private let headerContent: (() -> T)?
    
    init(_ content: PostContent, boardId: String, threadId: Int,
         headerContent: (() -> T)? = nil) {
        
        self.content = content
        self.boardId = boardId
        self.threadId = threadId
        self.headerContent = headerContent
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
                    makeAuthorText(content.author) +
                    Text(" on \(DateFormatter.standard().string(from: content.date))")
                
                if let headerContent = self.headerContent {
                    headerContent()
                }
            }
            
            RichTextView(
                content.content ?? "",
                boardId: boardId,
                threadId: threadId)
            
            Spacer()
        }
    }
    
    private func makeAuthorText(_ user: User) -> Text {
        if let name = user.name {
            return Text(name).bold()
        } else if let trip = user.tripCode {
            return Text(trip).bold()
        } else {
            return Text("")
        }
    }
}

// MARK: - PostContent

struct PostContent {
    let id: Int
    let author: User
    let date: Date
    let subject: String?
    let content: String?
    let attachment: Asset?
    let sticky: Bool
    let closed: Bool
    let archived: Bool
    let archivedDate: Date?
}

// MARK: - Extensions
extension PostView where T == EmptyView {
    init(_ content: PostContent, boardId: String, threadId: Int) {
        self.init(
            content,
            boardId: boardId,
            threadId: threadId,
            headerContent: nil)
    }
}

// MARK: - Thread Extensions

extension Thread {
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
                    author: User(
                        name: "Anonymous",
                        tripCode: nil,
                        isSecure: false),
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
