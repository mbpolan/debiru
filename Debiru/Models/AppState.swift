//
//  AppState.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Observation

/// The global state of the app.
@Observable
class AppState: Codable {
    var boards: [Board] = []
    
    init() {
        self.boards = []
    }
    
    init(boards: [Board]) {
        self.boards = boards
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        boards = try values.decode([Board].self, forKey: .boards)
    }
}

extension AppState {
    private enum CodingKeys: String, CodingKey {
        case boards
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boards, forKey: .boards)
    }
}

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

struct OrderedFilter: Identifiable, Hashable, Equatable, Codable {
    let index: Int
    let filter: String
    
    var id: String {
        return "\(index)\(filter)"
    }
}
