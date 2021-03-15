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
            HStack(alignment: .center) {
                Text("/\(board.id)/")
                    .font(.title)
                
                Text(board.title)
                    .font(.headline)
            }
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
    static var previews: some View {
        BoardListView()
            .environmentObject(AppState(
                                currentBoardId: "g",
                                boards: [
                                    Board(
                                        id: "f",
                                        title: "Foobar",
                                        description: "Foobar is an board on some imageboard for discussing imageboards")
                                ]))
    }
}
