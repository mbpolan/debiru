//
//  FourChanDataProvider.swift
//  Debiru
//
//  Created by Mike Polan on 3/14/21.
//

import Combine
import Foundation

struct FourChanDataProvider: DataProvider {
    private let baseUrl = "https://a.4cdn.org"
    
    func getBoards(_ completion: @escaping(_: Result<[Board], Error>) -> Void) -> AnyCancellable? {
        if let url = URL(string: "\(baseUrl)/boards.json") {
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
        if let url = URL(string: "\(baseUrl)/\(board.id)/catalog.json") {
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
                    let threads = value.map { page in
                        return page.threads.map { thread in
                            Thread(
                                id: thread.id,
                                poster: thread.poster,
                                subject: thread.subject,
                                content: thread.content)
                        }
                    }.reduce([], +)
                    
                    completion(.success(threads))
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
    
    private enum CodingKeys: String, CodingKey {
        case id = "no"
        case subject = "sub"
        case poster = "name"
        case content = "com"
    }
}
