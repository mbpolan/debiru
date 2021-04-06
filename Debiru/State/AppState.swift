//
//  AppState.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var quickSearchOpen: Bool = false
    @Published var currentItem: ViewableItem?
    @Published var boards: [Board] = []
    @Published var openItems: [ViewableItem]
    @Published var openImageData: Data?
    @Published var autoRefresh: Bool = false
    
    init() {
        self.boards = []
        self.openItems = []
    }
    
    init(currentItem: ViewableItem?, boards: [Board], openItems: [ViewableItem]) {
        self.currentItem = currentItem
        self.boards = boards
        self.openItems = openItems
    }
}

enum ViewableItem: Identifiable, Hashable {
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
