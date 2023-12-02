//
//  PostView.swift
//  Debiru
//
//  Created by Mike Polan on 3/27/21.
//

import FlagKit
import SwiftUI

// MARK: - View

struct PostView<T>: View where T: View {
    private let content: PostContent
    private let boardId: String
    private let threadId: Int
    private let parentPostId: Int?
    private let showReplies: Bool
    private let onActivate: () -> Void
    private let onLink: (_: Link) -> Void
    private let headerContent: (() -> T)?
    
    init(_ content: PostContent,
         boardId: String,
         threadId: Int,
         parentPostId: Int?,
         showReplies: Bool,
         onActivate: @escaping() -> Void,
         onLink: @escaping(_: Link) -> Void,
         headerContent: (() -> T)? = nil) {
        
        self.content = content
        self.boardId = boardId
        self.threadId = threadId
        self.parentPostId = parentPostId
        self.showReplies = showReplies
        self.onActivate = onActivate
        self.onLink = onLink
        self.headerContent = headerContent
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(content.subject?.unescapeHTML() ?? "")
                .font(.title)
                .onTapGesture(perform: onActivate)
            
            HStack(alignment: .firstTextBaseline, spacing: 3.0) {
                if content.sticky {
                    Image(systemName: "pin.fill")
                        .foregroundColor(Color(PFColor.systemGreen))
                        .help("This thread is stickied")
                }
                
                if content.closed {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Color(PFColor.systemRed))
                        .help("This thread is locked")
                }
                
                Group {
                    Text(" #\(String(content.id)) ")
                        .bold()
                        .hoverEffect(backgroundColor: .blue, foregroundColor: .white)
                        .onTapGesture(perform: onActivate)
                    
                    // show the author and post date alongside the post id on macos
#if os(macOS)
                    makeAuthorText(content.author)
                    Text("\(DateFormatter.standard().string(from: content.date))")
#endif
                }
                
                if let headerContent = self.headerContent {
                    headerContent()
                }
            }
           
            // show the author and post date below the title on ios
#if os(iOS)
            makeAuthorText(content.author)
            Text("\(DateFormatter.standard().string(from: content.date))")
#endif
            
            if showReplies {
                ReplyHStack(postIds: content.replies) { postId in
                    guard let url = PostLink.makeURL(
                        boardId: boardId,
                        threadId: threadId,
                        postId: postId) else { return }
                    
                    guard let link = handleInternalLink(url) else { return }
                    onLink(link)
                }
            }
            
            RichTextView(
                content.content ?? "",
                boardId: boardId,
                threadId: threadId,
                parentPostId: parentPostId,
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
            color = Color(PFColor.systemRed)
            help = "Administrator"
        case .developer:
            color = Color(PFColor.systemOrange)
            help = "Developer"
        case .founder:
            color = Color(PFColor.systemPink)
            help = "Founder"
        case .manager:
            color = Color(PFColor.systemBlue)
            help = "Manager"
        case .moderator:
            color = Color(PFColor.systemPurple)
            help = "Moderator"
        case .verified:
            color = Color(PFColor.systemTeal)
            help = "Verified user"
        default:
            break
        }
        
        return HStack {
            Text(username)
                .bold()
                .foregroundColor(color ?? Color(PFTextColor))
                .help(help ?? username)
            
            if let country = user.country {
                makeCountryFlag(country)
            }
        }
    }
    
    private func makeCountryFlag(_ country: User.Country) -> AnyView {
        switch country {
        case .code(let code, let name):
            if let image = Flag(countryCode: code)?.originalImage {
#if os(macOS)
                return Image(nsImage: image)
                    .help(name)
                    .clipShape(Circle())
                    .toErasedView()
#elseif os(iOS)
                return Image(uiImage: image)
                    .help(name)
                    .clipShape(Circle())
                    .toErasedView()
#endif
            } else {
                return Image(systemName: "flag")
                    .help(name)
                    .toErasedView()
            }
            
        case .fake(let code, let name):
            return CountryFlagImage(code: code, name: name)
                .clipShape(Circle())
                .toErasedView()
            
        default:
            return Image(systemName: "flag")
                .help("Unknown country")
                .toErasedView()
        }
    }
    
    private func handleLink(_ url: URL) -> Void {
        var link: Link? = nil
        
        switch url.scheme {
        // links to a board or post
        case "applewebdata":
            link = handleInternalLink(url)
        // links to external websites
        case "http", "https":
            link = handleExternalLink(url)
            
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
        
        // determine what kind of link this is based on how many segments
        // are present in the path:
        // a. four segments: this indicates a link to post
        // b. two segments: a board followed by a destination
        // b. a single segment: a link to a board
        if parts.count == 4,
           let boardId = parts.first,
           let threadId = Int(parts[2]),
           let postId = Int(parts.last ?? "") {
            
            return PostLink(
                url: url,
                boardId: boardId,
                threadId: threadId,
                postId: postId)
        } else if parts.count == 2,
                  let boardId = parts.first,
                  let filter = parts.last {
            
            // the filter is applied on the target board
            return BoardLink(
                url: url,
                boardId: boardId,
                filter: filter)
        } else if parts.count == 1,
                  let boardId = parts.first {
            
            return BoardLink(
                url: url,
                boardId: boardId,
                filter: nil)
        }
        
        print("Unknown link: \(url.path)")
        return nil
    }
    
    private func handleExternalLink(_ url: URL) -> Link? {
        return WebLink(url: url)
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
}

// MARK: - Extensions
extension PostView where T == EmptyView {
    init(_ content: PostContent,
         boardId: String,
         threadId: Int,
         parentPostId: Int?,
         showReplies: Bool,
         onActivate: @escaping() -> Void,
         onLink: @escaping(_: Link) -> Void) {
        
        self.init(
            content,
            boardId: boardId,
            threadId: threadId,
            parentPostId: parentPostId,
            showReplies: showReplies,
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
                        tag: nil,
                        country: nil),
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
                 parentPostId: nil,
                 showReplies: false,
                 onActivate: { },
                 onLink: { _ in })
    }
}
