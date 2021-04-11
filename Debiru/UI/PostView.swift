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
    private let onActivate: () -> Void
    private let onLink: (_: Link) -> Void
    private let headerContent: (() -> T)?
    
    init(_ content: PostContent,
         boardId: String,
         threadId: Int,
         onActivate: @escaping() -> Void,
         onLink: @escaping(_: Link) -> Void,
         headerContent: (() -> T)? = nil) {
        
        self.content = content
        self.boardId = boardId
        self.threadId = threadId
        self.onActivate = onActivate
        self.onLink = onLink
        self.headerContent = headerContent
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(content.getSubject() ?? "")
                .font(.title)
                .onTapGesture(perform: onActivate)
            
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
                
                Group {
                    Text("#\(String(content.id)) ")
                        .bold()
                        .hoverEffect()
                        .onTapGesture(perform: onActivate)
                    
                    makeAuthorText(content.author)
                    Text("\(DateFormatter.standard().string(from: content.date))")
                }
                
                if let headerContent = self.headerContent {
                    headerContent()
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                ForEach(content.replies, id: \.self) { replyId in
                    Text(">>\(String(replyId))")
                        .foregroundColor(Color(NSColor.linkColor))
                        .underline()
                        .onTapGesture {
                            guard let url = PostLink.makeURL(
                                    boardId: boardId,
                                    threadId: threadId,
                                    postId: content.id) else { return }
                            
                            guard let link = handleInternalLink(url) else { return }
                            onLink(link)
                        }
                        .onHover { hover in
                            if hover {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }
            }
            
            RichTextView(
                content.content ?? "",
                boardId: boardId,
                threadId: threadId,
                onLink: handleLink)
            
            Spacer()
        }
    }
    
    private func makeAuthorText(_ user: User) -> some View {
        // set the name based on the username or tripcode
        var username: String = ""
        if let name = user.name {
            username = name
        } else if let trip = user.tripCode {
            username = trip
        }
        
        // apply extra styling if the user has a particular tag
        var color: Color?
        var help: String?
        
        switch user.tag {
        case .administrator:
            color = Color(NSColor.systemRed)
            help = "Administrator"
        case .developer:
            color = Color(NSColor.systemOrange)
            help = "Developer"
        case .founder:
            color = Color(NSColor.systemPink)
            help = "Founder"
        case .manager:
            color = Color(NSColor.systemBlue)
            help = "Manager"
        case .moderator:
            color = Color(NSColor.systemPurple)
            help = "Moderator"
        case .verified:
            color = Color(NSColor.systemTeal)
            help = "Verified user"
        default:
            break
        }
        
        return Text(username)
            .bold()
            .foregroundColor(color ?? Color(NSColor.textColor))
            .help(help ?? username)
    }
    
    private func handleLink(_ url: URL) -> Void {
        var link: Link? = nil
        
        switch url.scheme {
        // links to a board or post
        case "applewebdata":
            link = handleInternalLink(url)
            
        default:
            print("Unknown URL scheme: \(url.scheme ?? "nil")")
        }
        
        if let link = link {
            onLink(link)
        }
    }
    
    private func handleInternalLink(_ url: URL) -> Link? {
        let parts = url.path
            .components(separatedBy: "/")
            .filter { !$0.isEmpty }
        
        // if there are four segments, this indicates a link to post
        // otherwise, a single segment is a link to a board
        if parts.count == 4,
           let boardId = parts.first,
           let threadId = Int(parts[2]),
           let postId = Int(parts.last ?? "") {
            
            return PostLink(
                url: url,
                boardId: boardId,
                threadId: threadId,
                postId: postId)
        } else if parts.count == 1,
                  let boardId = parts.first {
            
            return BoardLink(
                url: url,
                boardId: boardId)
        }
        
        print("Unknown link: \(url.path)")
        return nil
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
    let replies: [Int]
    
    func getSubject() -> String? {
        if let subject = self.subject {
            return CFXMLCreateStringByUnescapingEntities(nil, subject as CFString, nil) as String
        }
        
        return nil
    }
}

// MARK: - Extensions
extension PostView where T == EmptyView {
    init(_ content: PostContent,
         boardId: String,
         threadId: Int,
         onActivate: @escaping() -> Void,
         onLink: @escaping(_: Link) -> Void) {
        
        self.init(
            content,
            boardId: boardId,
            threadId: threadId,
            onActivate: onActivate,
            onLink: onLink,
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
            archivedDate: nil,
            replies: [])
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
            archivedDate: self.archivedDate,
            replies: self.replies)
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
                        isSecure: false,
                        tag: nil),
                    date: Date(),
                    subject: "Something",
                    content: "Ain't this cool?",
                    attachment: nil,
                    sticky: false,
                    closed: false,
                    archived: false,
                    archivedDate: nil,
                    replies: []),
                 boardId: "f",
                 threadId: 321,
                 onActivate: { },
                 onLink: { _ in })
    }
}
