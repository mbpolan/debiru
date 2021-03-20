//
//  BoardListView.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

import SwiftUI

// MARK: - View

struct BoardListView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List(appState.boards, id: \.self) { board in
            BoardListCellView(board)
                .onTapGesture {
                    handleSelectBoard(board)
                }
        }
    }
    
    private func handleSelectBoard(_ board: Board) {
        NotificationCenter.default.post(name: .showBoard, object: board)
    }
}

// MARK: - Preview

struct BoardListView_Previews: PreviewProvider {
    private static let board = Board(
        id: "f",
        title: "Foobar",
        description: "Foobar is an board on some imageboard for discussing imageboards")
    
    static var previews: some View {
        BoardListView()
            .environmentObject(AppState(
                                currentItem: .board(board),
                                boards: [board],
                                openItems: []))
    }
}
