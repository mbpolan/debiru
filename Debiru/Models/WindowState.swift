//
//  WindowState.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import Observation
import SwiftUI

/// A model that represents the current state of a window group.
@Observable
class WindowState {
    var route: NavigationPath = .init()
    var currentItem: ViewableItem?
    
    func clearNavigation() {
        self.route = NavigationPath()
    }
    
    func navigate(boardId: String) {
        self.route.append(ViewableItem.board(boardId: boardId))
    }
    
    func navigate(boardId: String, threadId: Int) {
        self.route.append(ViewableItem.thread(boardId: boardId, threadId: threadId))
    }
    
    func navigate(asset: Asset) {
        self.route.append(ViewableItem.asset(asset: asset))
    }
    
    func navigateToDownloads() {
        self.route.append(ViewableItem.downloads)
    }
    
    func navigateToSettings() {
        self.route.append(ViewableItem.settings)
    }
}

/// An enumeration of possible items that can be viewed in the app.
enum ViewableItem: Identifiable, Hashable, Codable {
    case board(boardId: String)
    case thread(boardId: String, threadId: Int)
    case asset(asset: Asset)
    case downloads
    case settings
    
    var id: String {
        switch self {
        case .board(let boardId):
            return boardId
        case .thread(let boardId, let threadId):
            return "\(boardId)-\(threadId)"
        case .asset(let asset):
            return "\(asset.boardId)-\(asset.id)"
        case .downloads:
            return "downloads"
        case .settings:
            return "settings"
        }
    }
}

extension ViewableItem {
    private enum CodingKeys: String, CodingKey {
        case board
        case thread
    }
    
    enum ViewableItemCodingError: Error {
        case decoding(String)
    }
    
    private struct BoardThreadTuple: Codable {
        let board: Board
        let thread: Thread
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // FIXME
//        if let board = try? values.decode(Board.self, forKey: .board) {
//            self = .board(board)
//        } else if let pair = try? values.decode(BoardThreadTuple.self, forKey: .thread) {
//            self = .thread(pair.board, pair.thread)
//        }
        
        throw ViewableItemCodingError.decoding("Failed to decode: \(dump(values))")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .board(let board):
            try container.encode(board, forKey: .board)
        case .thread(let board, let thread):
            break
            // FIXME
//            try container.encode(BoardThreadTuple(
//                                    board: board,
//                                    thread: thread), forKey: .thread)
        case .asset(let asset):
            break
        case .downloads:
            break
        case .settings:
            break
        }
        
    }
}
