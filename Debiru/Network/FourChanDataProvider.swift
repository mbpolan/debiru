//
//  FourChanDataProvider.swift
//  Debiru
//
//  Created by Mike Polan on 3/14/21.
//

import Combine
import Foundation

struct FourChanDataProvider: DataProvider {
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
                                width: width,
                                height: height,
                                thumbnailWidth: thumbWidth,
                                thumbnailHeight: thumbHeight,
                                filename: filename,
                                extension: ext)
                        }
                        
                        return Thread(
                            id: thread.id,
                            poster: thread.poster,
                            subject: thread.subject,
                            content: thread.content,
                            sticky: thread.sticky == 1,
                            closed: thread.closed == 1,
                            attachment: asset)
                    }
                }.reduce([], +)
            },
            completion: completion)
    }
    
    func getImage(for asset: Asset, board: Board, completion: @escaping(_: Result<Data, Error>) -> Void) -> AnyCancellable? {
        
        let key = "\(assetBaseUrl)/\(board.id)/\(asset.id)\(asset.extension)"
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
    let subject: String?
    let poster: String
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
    
    private enum CodingKeys: String, CodingKey {
        case id = "no"
        case subject = "sub"
        case poster = "name"
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
    }
}
