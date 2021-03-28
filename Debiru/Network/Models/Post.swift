//
//  Post.swift
//  Debiru
//
//  Created by Mike Polan on 3/23/21.
//

import Foundation

struct Post: Identifiable, Hashable {
    let id: Int
    let boardId: String
    let threadId: Int
    let author: String
    let date: Date
    let subject: String?
    let content: String?
    let sticky: Bool
    let closed: Bool
    let attachment: Asset?
    let archived: Bool
    let archivedDate: Date?
}
