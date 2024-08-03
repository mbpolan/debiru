//
//  Post.swift
//  Debiru
//
//  Created by Mike Polan on 3/23/21.
//

import Foundation

struct Post: Identifiable, Hashable, Codable {
    let id: Int
    let boardId: String
    let threadId: Int
    let isRoot: Bool
    let author: User
    let date: Date
    let replyToId: Int?
    let subject: String?
    let content: String?
    let body: AttributedString?
    let sticky: Bool
    let closed: Bool
    let spoileredImage: Bool
    let attachment: Asset?
    let threadStatistics: ThreadStatistics?
    let archived: Bool
    let archivedDate: Date?
    let replies: [Int]
}
