//
//  FourChanDataProvider.swift
//  Debiru
//
//  Created by Mike Polan on 3/14/21.
//

import Combine
import Foundation
import SwiftSoup

struct FourChanDataProvider: DataProvider {
    private let webBaseUrl = "https://4chan.org"
    private let webBoardsBaseUrl = "https://boards.4chan.org"
    private let apiBaseUrl = "https://a.4cdn.org"
    private let assetBaseUrl = "https://i.4cdn.org"
    private let imageCache: DataCache = DataCache()
    
    func getBoards(_ completion: @escaping(_: Result<[Board], Error>) -> Void) -> AnyCancellable? {
        return getData(
            url: "\(apiBaseUrl)/boards.json",
            mapper: { (value: BoardsResponse) in
                return value.boards.map { model in
                    Board(
                        id: model.id,
                        title: model.title,
                        description: model.description)
                }
            },
            completion: completion)
    }
    
    func getCatalog(for board: Board, completion: @escaping(_: Result<[Thread], Error>) -> Void) -> AnyCancellable? {
        
        return getData(
            url: "\(apiBaseUrl)/\(board.id)/catalog.json",
            mapper: { (value: [CatalogModel]) in
                return value.map { page in
                    return page.threads.map { thread in
                        var asset: Asset?
                        if let id = thread.assetId,
                           let width = thread.imageWidth,
                           let height = thread.imageHeight,
                           let thumbWidth = thread.thumbnailWidth,
                           let thumbHeight = thread.thumbnailHeight,
                           let filename = thread.filename,
                           let ext = thread.extension {
                            
                            asset = Asset(
                                id: id,
                                boardId: board.id,
                                width: width,
                                height: height,
                                thumbnailWidth: thumbWidth,
                                thumbnailHeight: thumbHeight,
                                filename: filename,
                                extension: ext)
                        }
                        
                        return Thread(
                            id: thread.id,
                            boardId: board.id,
                            author: User(
                                name: thread.author,
                                tripCode: thread.trip,
                                isSecure: thread.trip?.starts(with: "!!") ?? false),
                            date: Date(timeIntervalSince1970: TimeInterval(thread.time)),
                            subject: thread.subject,
                            content: thread.content,
                            sticky: thread.sticky == 1,
                            closed: thread.closed == 1,
                            attachment: asset,
                            statistics: ThreadStatistics(
                                replies: thread.replies,
                                images: thread.images,
                                uniquePosters: thread.uniqueUsers,
                                bumpLimit: thread.bumpLimit == 1,
                                imageLimit: thread.imageLimit == 1,
                                page: page.page))
                    }
                }.reduce([], +)
            },
            completion: completion)
    }
    
    func getPosts(for thread: Thread, completion: @escaping(_: Result<[Post], Error>) -> Void) -> AnyCancellable? {
        
        return getData(
            url: "\(apiBaseUrl)/\(thread.boardId)/thread/\(thread.id).json",
            mapper: { (value: ThreadPostsModel) in
                var postsToReplies: [Int: [Int]] = [:]
                
                // find all posts that this post references in its thread
                value.posts.forEach { post in
                    parseRepliesTo(post.content ?? "").forEach { reply in
                        if var existing = postsToReplies[reply] {
                            existing.append(post.id)
                        } else {
                            postsToReplies[reply] = [post.id]
                        }
                    }
                }
                
                return value.posts.map { post in
                    var asset: Asset?
                    if let id = post.assetId,
                       let width = post.imageWidth,
                       let height = post.imageHeight,
                       let thumbWidth = post.thumbnailWidth,
                       let thumbHeight = post.thumbnailHeight,
                       let filename = post.filename,
                       let ext = post.extension {
                        
                        asset = Asset(
                            id: id,
                            boardId: thread.boardId,
                            width: width,
                            height: height,
                            thumbnailWidth: thumbWidth,
                            thumbnailHeight: thumbHeight,
                            filename: filename,
                            extension: ext)
                    }
                    
                    var threadStatistics: ThreadStatistics?
                    if let replies = post.replies,
                       let images = post.images,
                       let uniquePosters = post.uniqueUsers {
                        threadStatistics = ThreadStatistics(
                            replies: replies,
                            images: images,
                            uniquePosters: uniquePosters,
                            bumpLimit: post.bumpLimit == 1,
                            imageLimit: post.imageLimit == 1,
                            page: nil)
                    }
                    
                    var archivedDate: Date? = nil
                    if let archiveTime = post.archiveTime {
                        archivedDate = Date(timeIntervalSince1970: TimeInterval(archiveTime))
                    }
                    
                    return Post(
                        id: post.id,
                        boardId: thread.boardId,
                        threadId: thread.id,
                        isRoot: post.replyTo == 0, // indicates original poster
                        author: User(
                            name: post.author,
                            tripCode: post.trip,
                            isSecure: post.trip?.starts(with: "!!") ?? false),
                        date: Date(timeIntervalSince1970: TimeInterval(post.time)),
                        subject: post.subject,
                        content: post.content,
                        sticky: post.sticky == 1,
                        closed: post.closed == 1,
                        attachment: asset,
                        threadStatistics: threadStatistics,
                        archived: post.archived == 1,
                        archivedDate: archivedDate,
                        replies: postsToReplies[post.id] ?? [])
                }
            },
            completion: completion)
    }
    
    func getImage(for asset: Asset, completion: @escaping(_: Result<Data, Error>) -> Void) -> AnyCancellable? {
        
        let key = "\(assetBaseUrl)/\(asset.boardId)/\(asset.id)\(asset.extension)"
        if let url = URL(string: key) {
            if let cachedImage = imageCache.get(forKey: key) {
                print("CACHE HIT: \(key)")
                completion(.success(cachedImage))
                return nil
            }
            
            return URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { output in
                    guard let response = output.response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse("Unreadable image response")
                    }
                    if response.statusCode != 200 {
                        throw NetworkError.invalidResponse("Failed to fetch image: \(key): \(response.statusCode)")
                    }
                    
                    return output.data
                }
                .eraseToAnyPublisher()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }, receiveValue: { (value: Data) in
                    imageCache.set(key, value: value)
                    completion(.success(value))
                })
        }
        
        return nil
    }
    
    func getURL(for board: Board) -> URL? {
        return URL(string: "\(webBaseUrl)/\(board.id)/")
    }
    
    func getURL(for thread: Thread) -> URL? {
        return URL(string: "\(webBoardsBaseUrl)/\(thread.boardId)/thread/\(thread.id)")
    }
    
    private func getData<S: Decodable, T>(
        url: String,
        mapper: @escaping(_ data: S) -> T,
        completion: @escaping(_: Result<T, Error>) -> Void) -> AnyCancellable? {
        
        if let url = URL(string: url) {
            return URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { output in
                    guard let response = output.response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse("Unreadable data response")
                    }
                    
                    if response.statusCode != 200 {
                        throw NetworkError.invalidResponse("Failed to fetch data: \(response.statusCode)")
                    }
                    
                    return output.data
                }
                .decode(type: S.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }, receiveValue: { value in
                    completion(.success(mapper(value)))
                })
        }
        
        return nil
    }
    
    private func parseRepliesTo(_ content: String) -> [Int] {
        guard let links = try? SwiftSoup.parseBodyFragment(content).select("a[href]") else {
            return []
        }
        
        return links.compactMap { link in
            if let href = try? link.attr("href"), href.starts(with: "#p") {
                return Int(href.dropFirst(2))
            }
            
            return nil
        }
    }
}

// MARK: - API models

fileprivate struct BoardsResponse: Codable {
    let boards: [BoardModel]
}

fileprivate struct BoardModel: Codable, Hashable {
    let id: String
    let title: String
    let description: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "board"
        case title
        case description = "meta_description"
    }
}

fileprivate struct CatalogModel: Codable {
    let page: Int
    let threads: [ThreadModel]
}

fileprivate struct ThreadModel: Codable {
    let id: Int
    let time: Int
    let subject: String?
    let author: String?
    let trip: String?
    let content: String?
    let sticky: Int?
    let closed: Int?
    let assetId: Int?
    let imageWidth: Int?
    let imageHeight: Int?
    let thumbnailWidth: Int?
    let thumbnailHeight: Int?
    let filename: String?
    let `extension`: String?
    let replies: Int
    let images: Int
    let uniqueUsers: Int?
    let bumpLimit: Int?
    let imageLimit: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id = "no"
        case time
        case subject = "sub"
        case author = "name"
        case trip
        case content = "com"
        case sticky
        case closed
        case assetId = "tim"
        case imageWidth = "w"
        case imageHeight = "h"
        case thumbnailWidth = "tn_w"
        case thumbnailHeight = "tn_h"
        case filename
        case `extension` = "ext"
        case replies
        case images
        case uniqueUsers = "unique_ips"
        case bumpLimit
        case imageLimit
    }
}

fileprivate struct ThreadPostsModel: Codable {
    let posts: [PostModel]
}

fileprivate struct PostModel: Codable {
    let id: Int
    let replyTo: Int
    let time: Int
    let subject: String?
    let author: String?
    let trip: String?
    let content: String?
    let sticky: Int?
    let closed: Int?
    let assetId: Int?
    let imageWidth: Int?
    let imageHeight: Int?
    let thumbnailWidth: Int?
    let thumbnailHeight: Int?
    let filename: String?
    let `extension`: String?
    let replies: Int?
    let images: Int?
    let uniqueUsers: Int?
    let bumpLimit: Int?
    let imageLimit: Int?
    let archived: Int?
    let archiveTime: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id = "no"
        case replyTo = "resto"
        case time
        case subject = "sub"
        case author = "name"
        case trip
        case content = "com"
        case sticky
        case closed
        case assetId = "tim"
        case imageWidth = "w"
        case imageHeight = "h"
        case thumbnailWidth = "tn_w"
        case thumbnailHeight = "tn_h"
        case filename
        case `extension` = "ext"
        case replies
        case images
        case uniqueUsers = "unique_ips"
        case bumpLimit
        case imageLimit
        case archived
        case archiveTime = "archived_on"
    }
}
