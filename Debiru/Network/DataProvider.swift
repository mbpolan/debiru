//
//  DataProvider.swift
//  Debiru
//
//  Created by Mike Polan on 3/14/21.
//

import Combine
import Foundation

protocol DataProvider {
    func post(_ submission: Submission, to board: Board, completion: @escaping(_: SubmissionResult) -> Void)
    
    func getBoards() async throws -> [Board]
    
    func getCatalog(for board: Board) async throws -> [Thread]
    
    func getPosts(for thread: Thread) async throws -> [Post]
    
    func getImage(for asset: Asset, variant: Asset.Variant) async throws -> Data?
    
    func getCountryFlagImage(for countryCode: String) async throws -> Data?
    
    func getURL(for board: Board) -> URL?
    
    func getURL(for thread: Thread) -> URL?
    
    func getURL(for asset: Asset) -> URL?
}

enum NetworkError: Error {
    case postError(String)
    case invalidResponse(String)
    case notFound
}
