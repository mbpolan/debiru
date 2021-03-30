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
}

struct PostLink: Link {
    let url: URL
    let boardId: String
    let threadId: Int
    let postId: Int
}
