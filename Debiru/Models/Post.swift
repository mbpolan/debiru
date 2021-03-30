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
    let isRoot: Bool
    let author: User
    let date: Date
    let subject: String?
    let content: String?
    let sticky: Bool
    let closed: Bool
    let attachment: Asset?
    let threadStatistics: ThreadStatistics?
    let archived: Bool
    let archivedDate: Date?
}
