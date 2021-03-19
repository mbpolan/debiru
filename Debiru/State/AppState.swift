//
//  AppState.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var currentBoardId: String?
    @Published var boards: [Board] = []
    @Published var openItems: [ViewableItem]
    
    init() {
        self.boards = []
        self.openItems = []
    }
    
    init(currentBoardId: String?, boards: [Board], openItems: [ViewableItem]) {
        self.currentBoardId = currentBoardId
        self.boards = boards
        self.openItems = openItems
    }
}

enum ViewableItem: Identifiable, Hashable {
    case board(Board)
    case thread(Thread)
    
    var id: String {
        switch self {
        case .board(let board):
            return board.id
        case .thread(let thread):
            return String(thread.id)
        }
    }
}
