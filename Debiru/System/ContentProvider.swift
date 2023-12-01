//
//  ContentProvider.swift
//  Debiru
//
//  Created by Mike Polan on 12/17/22.
//

import SwiftSoup
import Foundation

struct ContentProvider {
    static let instance: ContentProvider = .init()
    private let codeParser: CodeTagParser = .init()
    
    func processPosts(_ posts: [Post], in board: Board) -> [Post] {
        let threadId = posts.first?.threadId ?? 0
        
        do {
            // parse the content of all posts into html documents
            var postsToContent = try posts.reduce(into: [Int: ContentCache]()) { memo, cur in
                let html: Document
                if let content = cur.content {
                    html = try SwiftSoup.parseBodyFragment(content)
                } else {
                    html = SwiftSoup.Document("")
                }
                
                // parse anchors from the post content, and append text to indicate if a reply is for
                // the thread author
                let anchors = try html.getElementsByTag("a")
                for anchor in anchors {
                    // look for anchors in the form >>41923922 and compare the post id against the thread id
                    if let match = try? />>([0-9]+)/.wholeMatch(in: anchor.text()), Int(match.1) == threadId {
                        try anchor.text("\(anchor.text()) (OP)")
                    }
                }
                
                memo[cur.id] = .init(document: html, dirty: false)
            }
            
            // parse code content in posts
            if board.features.supportsCode {
                processCodeTags(posts, into: &postsToContent)
            }
            
            // build a map of post ids to their models
            return posts.map { post in
                // did this post's content change?
                guard let content = postsToContent[post.id],
                      content.dirty else { return post }
                
                return Post(id: post.id,
                            boardId: post.boardId,
                            threadId: post.threadId,
                            isRoot: post.isRoot,
                            author: post.author,
                            date: post.date,
                            replyToId: post.replyToId,
                            subject: post.subject,
                            content: try? content.document.html(),
                            sticky: post.sticky,
                            closed: post.closed,
                            spoileredImage: post.spoileredImage,
                            attachment: post.attachment,
                            threadStatistics: post.threadStatistics,
                            archived: post.archived,
                            archivedDate: post.archivedDate,
                            replies: post.replies)
            }
        } catch {
            print(error)
            return posts
        }
    }
    
    private func processCodeTags(_ posts: [Post], into contentCache: inout [Int: ContentCache]) {
        do {
            for post in posts {
                guard var content = contentCache[post.id] else { continue }
                
                // find all tags that have a css class indicating they contain code. if there are none, we can bail
                // out early
                let codeTags = try content.document.getElementsByClass("prettyprint")
//                if codeTags.isEmpty() {
//                    return
//                }
                
                for codeTag in codeTags {
                    let text = try codeTag.html()
                    try codeTag.html(codeParser.parse(text))
                }
                
                // flag this post content as modified
                // TODO: we can probably optimize this further by checking if anything was in fact changed
                content.dirty = true
                contentCache[post.id] = content
            }
        } catch {
            print(error)
        }
    }
}

extension ContentProvider {
    struct ContentCache {
        let document: Document
        var dirty: Bool
    }
}

fileprivate struct CodeTagParser {
    // common keywords found in various languages
    private let keywords = ["foreach", "for", "in", "func", "function", "var", "let", "const", "while", "loop", "do", "done", "if", "else", "elif"].joined(separator: "|")
    
    func parse(_ text: String) -> String {
        var str = text
        
        // wrap symbols in a span with css class "pun"
        str = str.replacingOccurrences(of: "([-|!|@|{|}|=|\\.|\\*]+)", with: "<span class=\"pun\">$1</span>", options: .regularExpression)
        
        // wrap keywords in a span with css class "kwd"
        str = str.replacingOccurrences(of: "(\(keywords))", with: "<span class=\"kwd\">$1</span>", options: .regularExpression)
        
        // wrap strings in a span with css class "str"
        str = str.replacingOccurrences(of: "'([^']+)'", with: "<span class=\"str\">'$1'</span>", options: .regularExpression)
        
        return str
    }
}
