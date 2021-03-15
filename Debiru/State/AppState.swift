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
    
    init() {
        self.boards = []
    }
    
    init(currentBoardId: String?, boards: [Board]) {
        self.currentBoardId = currentBoardId
        self.boards = boards
    }
}
