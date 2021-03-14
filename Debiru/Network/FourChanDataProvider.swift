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
                .decode(type: Boards.self, decoder: JSONDecoder())
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
                    completion(.success(value.boards))
                })
        }
        
        return nil
    }
}
