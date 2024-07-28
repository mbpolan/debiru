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
    
    func getBoard(for boardId: String) async throws -> Board?
    
    func getCatalog(for board: Board) async throws -> [Thread]
    
    func getPosts(for threadId: Int, in boardId: String) async throws -> [Post]
    
    func getCaptchaV3(from html: String) throws -> CaptchaV3Challenge
    
    func getImage(for asset: Asset, variant: Asset.Variant) async throws -> Data?
    
    func getCountryFlagImage(for countryCode: String) async throws -> Data?
    
    func getURL(for boardId: String) -> URL
    
    func getURL(for boardId: String, threadId: Int) -> URL
    
    func getURL(for asset: Asset, variant: Asset.Variant) -> URL
    
    func getURL(for captchaBoard: Board, threadId: Int) async throws -> URL
}

enum NetworkError: Error {
    case postError(String)
    case invalidResponse(String)
    case notFound
    case captchaError(String)
}
