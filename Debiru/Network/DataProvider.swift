//
//  DataProvider.swift
//  Debiru
//
//  Created by Mike Polan on 3/14/21.
//

import Combine
import Foundation

protocol DataProvider {
    
    func getBoards(_ completion: @escaping(_: Result<[Board], Error>) -> Void) -> AnyCancellable?
    
    func getCatalog(for board: Board, completion: @escaping(_: Result<[Thread], Error>) -> Void) -> AnyCancellable?
    
    func getPosts(for thread: Thread, completion: @escaping(_: Result<[Post], Error>) -> Void) -> AnyCancellable?
    
    func getImage(for asset: Asset, completion: @escaping(_: Result<Data, Error>) -> Void) -> AnyCancellable?
}

enum NetworkError: Error {
    case invalidResponse(String)
}
