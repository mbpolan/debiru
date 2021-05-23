//
//  AppState.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import SwiftUI

class AppState: ObservableObject, Codable {
    @Published var quickSearchOpen: Bool = false
    @Published var currentItem: ViewableItem?
    @Published var boards: [Board] = []
    @Published var openItems: [ViewableItem]
    @Published var openImageData: DownloadedAsset?
    @Published var openWebVideo: Asset?
    @Published var autoRefresh: Bool = false
    @Published var targettedPostId: Int?
    @Published var watchedThreads: [WatchedThread] = []
    @Published var boardFilters: [String: [OrderedFilter]] = [:]
    @Published var boardFilterEnablement: [String: Bool] = [:]
    
    init() {
        self.boards = []
        self.openItems = []
    }
    
    init(currentItem: ViewableItem?, boards: [Board], openItems: [ViewableItem]) {
        self.currentItem = currentItem
        self.boards = boards
        self.openItems = openItems
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        quickSearchOpen = try values.decode(Bool.self, forKey: .quickSearchOpen)
        currentItem = try values.decode(ViewableItem.self, forKey: .currentItem)
        boards = try values.decode([Board].self, forKey: .boards)
        openItems = try values.decode([ViewableItem].self, forKey: .openItems)
        openImageData = try values.decode(DownloadedAsset.self, forKey: .openImageData)
        openWebVideo = try values.decode(Asset.self, forKey: .openWebVideo)
        autoRefresh = try values.decode(Bool.self, forKey: .autoRefresh)
        watchedThreads = try values.decode([WatchedThread].self, forKey: .watchedThreads)
    }
}

extension AppState {
    private enum CodingKeys: String, CodingKey {
        case quickSearchOpen
        case currentItem
        case boards
        case openItems
        case openImageData
        case openWebVideo
        case autoRefresh
        case watchedThreads
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quickSearchOpen, forKey: .quickSearchOpen)
        try container.encode(currentItem, forKey: .currentItem)
        try container.encode(boards, forKey: .boards)
        try container.encode(openItems, forKey: .openItems)
        try container.encode(openImageData, forKey: .openImageData)
        try container.encode(autoRefresh, forKey: .autoRefresh)
        try container.encode(watchedThreads, forKey: .watchedThreads)
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
