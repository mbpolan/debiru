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
    private let sysBaseUrl = "https://sys.4chan.org"
    private let webBaseUrl = "https://4chan.org"
    private let webBoardsBaseUrl = "https://boards.4chan.org"
    private let apiBaseUrl = "https://a.4cdn.org"
    private let imageBaseUrl = "https://i.4cdn.org"
    private let staticBaseUrl = "https://s.4cdn.org"
    
    func post(_ submission: Submission, to board: Board, completion: @escaping(_: SubmissionResult) -> Void) {
        let body = MutableFormData()
        body.addField("MAX_FILE_SIZE", value: "2097152")
        body.addField("resto", value: String(submission.replyTo ?? 0))
        body.addField("com", value: String(submission.content))
        body.addField("mode", value: "regist")
        body.addField("t-response", value: submission.captchaResponse)
        body.addField("t-challenge", value: submission.captchaChallenge)
        
        if !submission.bump {
            body.addField("email", value: "sage")
        }
        
        if let asset = submission.asset {
            body.addFile("upfile", fileName: asset.fileName, value: asset.data)
        }
        
        let data = body.build()
        
        var request = URLRequest(url: URL(string: "\(sysBaseUrl)/\(board.id)/post")!)
        request.httpMethod = "POST"
        request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse("Unreadable response")))
                return
            }
            
            guard let data = data,
                  let responseData = String(data: data, encoding: .utf8) else {
                      completion(.failure(NetworkError.invalidResponse("Unreadable body")))
                      return
                  }
            
            if response.statusCode != 200 {
                completion(.failure(NetworkError.invalidResponse(
                    "Unexpected status code: \(response.statusCode)")))
                return
            }
            
            // validate the response to determine the actual result.
            // this is not a rest api call, so we unfortunately need to do some html parsing to
            // figure out what most likely happened after posting.
            completion(determinePostResult(responseData))
        }.resume()
    }
    
    func getBoards() async throws -> [Board] {
        return try await getData(
            url: "\(apiBaseUrl)/boards.json",
            mapper: { (value: BoardsResponse) in
                return value.boards.map { model in
                    Board(
                        id: model.id,
                        title: model.title,
                        description: model.description)
                }
            }) ?? []
    }
    
    func getCatalog(for board: Board) async throws -> [Thread] {
        return try await getData(
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
                           let ext = thread.extension,
                           let size = thread.fileSize {
                            
                            asset = Asset(
                                id: id,
                                boardId: board.id,
                                width: width,
                                height: height,
                                thumbnailWidth: thumbWidth,
                                thumbnailHeight: thumbHeight,
                                filename: filename,
                                extension: ext,
                                fileType: determineFileType(ext),
                                size: size)
                        }
                        
                        let country = determineCountryFlag(
                            code: thread.countryCode,
                            fakeCode: thread.trollCountryCode,
                            name: thread.countryName)
                        
                        return Thread(
                            id: thread.id,
                            boardId: board.id,
                            author: User(
                                name: thread.author,
                                tripCode: thread.trip,
                                isSecure: thread.trip?.starts(with: "!!") ?? false,
                                tag: thread.capCode?.toTag(),
                                country: country),
                            date: Date(timeIntervalSince1970: TimeInterval(thread.time)),
                            subject: thread.subject,
                            content: thread.content,
                            sticky: thread.sticky == 1,
                            closed: thread.closed == 1,
                            spoileredImage: thread.spoiler == 1,
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
            }) ?? []
    }
    
    func getPosts(for thread: Thread) async throws -> [Post] {
        return try await getData(
            url: "\(apiBaseUrl)/\(thread.boardId)/thread/\(thread.id).json",
            mapper: { (value: ThreadPostsModel) in
                var postsToReplies: [Int: [Int]] = [:]
                
                // find all posts that this post references in its thread
                value.posts.forEach { post in
                    parseRepliesTo(post.content ?? "").forEach { reply in
                        postsToReplies[reply, default: [Int]()].append(post.id)
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
                       let ext = post.extension,
                       let size = post.fileSize {
                        
                        asset = Asset(
                            id: id,
                            boardId: thread.boardId,
                            width: width,
                            height: height,
                            thumbnailWidth: thumbWidth,
                            thumbnailHeight: thumbHeight,
                            filename: filename,
                            extension: ext,
                            fileType: determineFileType(ext),
                            size: size)
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
                    
                    let country = determineCountryFlag(
                        code: post.countryCode,
                        fakeCode: post.trollCountryCode,
                        name: post.countryName)
                    
                    return Post(
                        id: post.id,
                        boardId: thread.boardId,
                        threadId: thread.id,
                        isRoot: post.replyTo == 0, // indicates original poster
                        author: User(
                            name: post.author,
                            tripCode: post.trip,
                            isSecure: post.trip?.starts(with: "!!") ?? false,
                            tag: post.capCode?.toTag(),
                            country: country),
                        date: Date(timeIntervalSince1970: TimeInterval(post.time)),
                        replyToId: post.replyTo == 0 ? nil : post.replyTo,
                        subject: post.subject,
                        content: post.content,
                        sticky: post.sticky == 1,
                        closed: post.closed == 1,
                        spoileredImage: post.spoiler == 1,
                        attachment: asset,
                        threadStatistics: threadStatistics,
                        archived: post.archived == 1,
                        archivedDate: archivedDate,
                        replies: postsToReplies[post.id] ?? [])
                }
            }) ?? []
    }
    
    func getCaptchaV3(from html: String) throws -> CaptchaV3Challenge {
        // parse the response as html and find the script tag containing the captcha message
        let root = try SwiftSoup.parse(html)
        guard let script = try root.head()?.getElementsByTag("script").first() else {
            throw NetworkError.captchaError("Failed to parse captcha response")
        }
        
        let scriptData = script.data()
        if scriptData.count == 0 {
            throw NetworkError.captchaError("Failed to find captcha message")
        }
        
        guard let start = scriptData.firstIndex(of: "{"),
              let end = scriptData.lastIndex(of: "}") else {
            throw NetworkError.captchaError("Failed to extract captcha message")
        }
        
        let message = scriptData[start...end]
        print(message)
        
        guard let jsonData = message.data(using: .utf8) else {
            throw NetworkError.captchaError("Failed to read captcha message")
        }
        
        let json = try JSONDecoder().decode(CaptchaV3MessageModel.self, from: jsonData)
        
        var twister: CaptchaV3Twister?
        if let twstr = json.twister {
            if let error = twstr.error {
                throw NetworkError.captchaError(error)
            }
            
            guard let image = twstr.image,
                  let imageData = Data(base64Encoded: image) else {
                throw NetworkError.captchaError("Invalid captcha image data")
            }
            
            guard let background = twstr.background,
                  let bgData = Data(base64Encoded: background) else {
                throw NetworkError.captchaError("Invalid captcha background data")
            }
            
            guard let challenge = twstr.challenge,
                  let imageWidth = twstr.imageWidth,
                  let imageHeight = twstr.imageHeight,
                  let backgroundWidth = twstr.backgroundWidth else {
                throw NetworkError.captchaError("Missing captcha challenge data")
            }
            
            twister = CaptchaV3Twister(
                challenge: challenge,
                image: imageData,
                background: bgData,
                imageSize: CGSize(width: imageWidth, height: imageWidth),
                backgroundSize: CGSize(width: backgroundWidth, height: imageHeight))
        }
        
        return CaptchaV3Challenge(twister: twister)
    }
    
    func getImage(for asset: Asset, variant: Asset.Variant) async throws -> Data? {
        // for thumbnail images, append an "s" to the asset id. some assets only have thumbnail variants available,
        // in which case don't modify the id
        let suffix = variant == .thumbnail ? "s" : ""
        let fileExtension = variant == .thumbnail ? ".jpg" : asset.extension
        
        let key = "\(imageBaseUrl)/\(asset.boardId)/\(asset.id)\(suffix)\(fileExtension)"
        return try await getImageData(key)
    }
    
    func getCountryFlagImage(for countryCode: String) async throws -> Data? {
        let key = "\(staticBaseUrl)/image/country/troll/\(countryCode.lowercased()).gif"
        return try await getImageData(key)
    }
    
    func getURL(for board: Board) -> URL? {
        return URL(string: "\(webBaseUrl)/\(board.id)/")
    }
    
    func getURL(for thread: Thread) -> URL? {
        return URL(string: "\(webBoardsBaseUrl)/\(thread.boardId)/thread/\(thread.id)")
    }
    
    func getURL(for asset: Asset) -> URL? {
        return URL(string: "\(imageBaseUrl)/\(asset.boardId)/\(asset.id)\(asset.extension)")
    }
    
    func getURL(for captchaBoard: Board, threadId: Int) async throws -> URL? {
        return URL(string: "https://sys.4chan.org/captcha?framed=1&board=\(captchaBoard.id)&thread_id=\(threadId)")
    }
    
    private func determineFileType(_ fileExtension: String) -> Asset.FileType {
        switch fileExtension.lowercased() {
        case ".gif":
            return .animatedImage
        case ".webm":
            return .webm
        default:
            return .image
        }
    }
    
    private func determineCountryFlag(code: String?, fakeCode: String?, name: String?) -> User.Country? {
        var country: User.Country?
        
        if let code = code,
           let name = name {
            // certain country codes are not standard, so we need to map them manually
            // to match an available flag image from FlagKit
            var realCode = code
            switch realCode {
                // england
            case "XE":
                realCode = "GB-ENG"
                // scotland
            case "XS":
                realCode = "GB-SCT"
                // wales
            case "XW":
                realCode = "GB-WLS"
            default:
                break
            }
            
            // XX indicates an unknown country code
            country = realCode == "XX" ? .unknown : .code(code: realCode, name: name)
            
        } else if let code = fakeCode,
                  let name = name {
            country = .fake(code: code, name: name)
        }
        
        return country
    }
    
    private func determinePostResult(_ response: String) -> SubmissionResult {
        do {
            let doc = try SwiftSoup.parse(response)
            let bodyText = try doc.body()?.text()
            
            // completed posts result in a success message and a redirect in a meta tag
            // errors usually appear in an element with id "errmsg"
            if (bodyText ?? "").contains("Post successful") {
                let metas = try doc.select("meta")
                let redirect = try metas.array()
                    .first { try $0.attr("http-equiv") == "refresh" }?.attr("content")
                
                let postId = redirect?.components(separatedBy: "#").last?.dropFirst() ?? ""
                if let postId = Int(postId) {
                    return .success(postId: postId)
                }
            } else if let error = try doc.select("#errmsg").first() {
                // strip all embedded links
                try error.select("a").remove()
                
                // sanitize the remaining html and stringify it
                var text = String(try SwiftSoup.clean(try error.text(), Whitelist.none()) ?? "Unknown error")
                
                // do some "best effort" clean up to remove any stray characters after sanitizing.
                // error messages sometimes have text like the following:
                //
                // lorem ipsum [<a ...>Click here</a>].
                //
                // we can clean up the square brackets and other similar artifacts to make the
                // message look more readable.
                text = text.replacingOccurrences(of: " []", with: "")
                
                return .failure(NetworkError.postError(text))
            }
            
            return .indeterminate
        } catch Exception.Error(_, let message) {
            return .failure(NetworkError.postError(message))
        } catch {
            return .failure(NetworkError.postError("Unknown error"))
        }
    }
    
    private func getData<S: Decodable, T>(url: String, mapper: @escaping(_ data: S) -> T) async throws -> T? {
        guard let url = URL(string: url) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return mapper(try JSONDecoder().decode(S.self, from: data))
    }
    
    private func getImageData(_ urlString: String) async throws -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        
        if let cachedImage = DataCache.shared.get(forKey: urlString) {
            return cachedImage
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        DataCache.shared.set(urlString, value: data)
        
        return data
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

fileprivate enum CapCode: String, Codable {
    case administrator = "admin"
    case administratorHighlight = "admin_highlight"
    case moderator = "mod"
    case manager
    case developer
    case verified
    
    func toTag() -> User.Tag {
        switch self {
        case .administrator, .administratorHighlight:
            return .administrator
        case .moderator:
            return .moderator
        case .manager:
            return .manager
        case .developer:
            return .developer
        case .verified:
            return .verified
        }
    }
}

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
    let capCode: CapCode?
    let countryCode: String?
    let trollCountryCode: String?
    let countryName: String?
    let trip: String?
    let content: String?
    let sticky: Int?
    let closed: Int?
    let spoiler: Int?
    let assetId: Int?
    let imageWidth: Int?
    let imageHeight: Int?
    let thumbnailWidth: Int?
    let thumbnailHeight: Int?
    let filename: String?
    let `extension`: String?
    let fileSize: Int64?
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
        case capCode = "capcode"
        case countryCode = "country"
        case trollCountryCode = "troll_country"
        case countryName = "country_name"
        case trip
        case content = "com"
        case sticky
        case closed
        case spoiler
        case assetId = "tim"
        case imageWidth = "w"
        case imageHeight = "h"
        case thumbnailWidth = "tn_w"
        case thumbnailHeight = "tn_h"
        case filename
        case `extension` = "ext"
        case fileSize = "fsize"
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
    let capCode: CapCode?
    let countryCode: String?
    let trollCountryCode: String?
    let countryName: String?
    let trip: String?
    let content: String?
    let sticky: Int?
    let closed: Int?
    let spoiler: Int?
    let assetId: Int?
    let imageWidth: Int?
    let imageHeight: Int?
    let thumbnailWidth: Int?
    let thumbnailHeight: Int?
    let filename: String?
    let `extension`: String?
    let fileSize: Int64?
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
        case capCode = "capcode"
        case countryCode = "country"
        case trollCountryCode = "troll_country"
        case countryName = "country_name"
        case trip
        case content = "com"
        case sticky
        case closed
        case spoiler
        case assetId = "tim"
        case imageWidth = "w"
        case imageHeight = "h"
        case thumbnailWidth = "tn_w"
        case thumbnailHeight = "tn_h"
        case filename
        case `extension` = "ext"
        case fileSize = "fsize"
        case replies
        case images
        case uniqueUsers = "unique_ips"
        case bumpLimit
        case imageLimit
        case archived
        case archiveTime = "archived_on"
    }
}

fileprivate struct CaptchaV3MessageModel: Codable {
    let twister: CaptchaV3TwisterModel?
    
    private enum CodingKeys: String, CodingKey {
        case twister = "twister"
    }
}

fileprivate struct CaptchaV3TwisterModel: Codable {
    let challenge: String?
    let ttl: Int?
    let cd: Int?
    let image: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let background: String?
    let backgroundWidth: Int?
    let error: String?
    
    private enum CodingKeys: String, CodingKey {
        case challenge
        case ttl
        case cd
        case image = "img"
        case imageWidth = "img_width"
        case imageHeight = "img_height"
        case background = "bg"
        case backgroundWidth = "bg_width"
        case error
    }
}
