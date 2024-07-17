//
//  WindowState.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import Observation

/// A model that represents the current state of a window group.
@Observable
class WindowState {
    var currentItem: ViewableItem?
}

/// An enumeration of possible items that can be viewed in the app.
enum ViewableItem: Identifiable, Hashable, Codable {
    case board(Board)
    case thread(Board?, Thread)
    
    var id: String {
        switch self {
        case .board(let board):
            return board.id
        case .thread(_, let thread):
            return String(thread.id)
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
        let board: Board?
        let thread: Thread
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let board = try? values.decode(Board.self, forKey: .board) {
            self = .board(board)
        } else if let pair = try? values.decode(BoardThreadTuple.self, forKey: .thread) {
            self = .thread(pair.board, pair.thread)
        }
        
        throw ViewableItemCodingError.decoding("Failed to decode: \(dump(values))")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .board(let board):
            try container.encode(board, forKey: .board)
        case .thread(let board, let thread):
            try container.encode(BoardThreadTuple(
                                    board: board,
                                    thread: thread), forKey: .thread)
        }
        
    }
}
