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
    
    func getBoards(_ completion: @escaping(_: Result<[Board], Error>) -> Void) -> AnyCancellable? {
        if let url = URL(string: "\(apiBaseUrl)/boards.json") {
            return URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { output in
                    guard let response = output.response as? HTTPURLResponse,
                          response.statusCode == 200 else {
                        throw NetworkError.invalidResponse("Failed to fetch data")
                    }
                    
                    return output.data
                }
                .decode(type: BoardsResponse.self, decoder: JSONDecoder())
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
                    let boards = value.boards.map { model in
                        Board(
                            id: model.id,
                            title: model.title,
                            description: model.description)
                    }
                    
                    completion(.success(boards))
                })
        }
        
        return nil
    }
    
    func getCatalog(for board: Board, completion: @escaping(_: Result<[Thread], Error>) -> Void) -> AnyCancellable? {
        if let url = URL(string: "\(apiBaseUrl)/\(board.id)/catalog.json") {
            return URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { output in
                    guard let response = output.response as? HTTPURLResponse,
                          response.statusCode == 200 else {
                        throw NetworkError.invalidResponse("Failed to fetch data")
                    }
                    
                    return output.data
                }
                .decode(type: [CatalogModel].self, decoder: JSONDecoder())
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
                    let threads: [Thread] = value.map { page in
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
                    
                    completion(.success(threads))
                })
        }
        
        return nil
    }
    
    func getImage(for asset: Asset, board: Board, completion: @escaping(_: Result<Data, Error>) -> Void) -> AnyCancellable? {
        if let url = URL(string: "\(assetBaseUrl)/\(board.id)/\(asset.id)\(asset.extension)") {
            return URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { output in
                    guard let response = output.response as? HTTPURLResponse,
                          response.statusCode == 200 else {
                        throw NetworkError.invalidResponse("Failed to fetch data")
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
                }, receiveValue: { value in
                    completion(.success(value))
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
