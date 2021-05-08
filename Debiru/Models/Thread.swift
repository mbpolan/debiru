//
//  Thread.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

import Foundation

struct Thread: Identifiable, Hashable, Codable {
    let id: Int
    let boardId: String
    let author: User
    let date: Date
    let subject: String?
    let content: String?
    let sticky: Bool
    let closed: Bool
    let spoileredImage: Bool
    let attachment: Asset?
    let statistics: ThreadStatistics
}

struct ThreadStatistics: Equatable, Hashable, Codable {
    let replies: Int
    let images: Int
    let uniquePosters: Int?
    let bumpLimit: Bool
    let imageLimit: Bool
    let page: Int?
    
    static var unknown: ThreadStatistics {
        return ThreadStatistics(
            replies: 0,
            images: 0,
            uniquePosters: nil,
            bumpLimit: false,
            imageLimit: false,
            page: nil)
    }
}

struct WatchedThread: Identifiable, Hashable, Codable {
    let thread: Thread
    let lastPostId: Int
    let totalNewPosts: Int
    let nowArchived: Bool
    let nowDeleted: Bool
    
    var id: Int {
        return thread.id
    }
}

extension WatchedThread {
    static func initial(_ thread: Thread) -> WatchedThread {
        return WatchedThread(
            thread: thread,
            lastPostId: thread.id, // corresponds to the first post
            totalNewPosts: 0,
            nowArchived: false,
            nowDeleted: false)
    }
    
    static func initial(_ thread: Thread, posts: [Post]) -> WatchedThread {
        return WatchedThread(
            thread: thread,
            lastPostId: posts.last?.id ?? 0,
            totalNewPosts: 0,
            nowArchived: posts.first?.archived ?? false,
            nowDeleted: false)
    }
}
