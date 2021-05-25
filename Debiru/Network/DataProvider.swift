//
//  DataProvider.swift
//  Debiru
//
//  Created by Mike Polan on 3/14/21.
//

import Combine
import Foundation

protocol DataProvider {
    
    func post(_ submission: Submission, to board: Board, completion: @escaping(_: Result<Void, Error>) -> Void)
    
    func getBoards(_ completion: @escaping(_: Result<[Board], Error>) -> Void) -> AnyCancellable?
    
    func getCatalog(for board: Board, completion: @escaping(_: Result<[Thread], Error>) -> Void) -> AnyCancellable?
    
    func getPosts(for thread: Thread, completion: @escaping(_: Result<[Post], Error>) -> Void) -> AnyCancellable?
    
    func getImage(for asset: Asset, completion: @escaping(_: Result<Data, Error>) -> Void) -> AnyCancellable?
    
    func getCountryFlagImage(for countryCode: String, completion: @escaping(_: Result<Data, Error>) -> Void) -> AnyCancellable?
    
    func getURL(for board: Board) -> URL?
    
    func getURL(for thread: Thread) -> URL?
    
    func getURL(for asset: Asset) -> URL?
}

enum NetworkError: Error {
    case invalidResponse(String)
}
