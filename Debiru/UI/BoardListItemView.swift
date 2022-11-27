//
//  BoardListItemView.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import SwiftUI

// MARK: - View

struct BoardListItemView: View {
    private let board: Board
    
    init(_ board: Board) {
        self.board = board
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text("/\(board.id)/")
            Text(board.title)
        }
    }
}

// MARK: - Preview

struct BoardListItemView_Previews: PreviewProvider {
    static var previews: some View {
        BoardListItemView(Board(
                            id: "f",
                            title: "Foobar",
                            description: "The board for all things foobar"))
    }
}
