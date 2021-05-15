//
//  Link.swift
//  Debiru
//
//  Created by Mike Polan on 3/29/21.
//

import Foundation

protocol Link {
    var url: URL { get }
}

struct WebLink: Link {
    let url: URL
}

struct BoardLink: Link {
    let url: URL
    let boardId: String
    let filter: String?
}

struct PostLink: Link {
    let url: URL
    let boardId: String
    let threadId: Int
    let postId: Int
}

extension PostLink {
    static func makeURL(boardId: String, threadId: Int, postId: Int) -> URL? {
        return URL(string: "/\(boardId)/thread/\(String(threadId))/\(postId)")
    }
}
