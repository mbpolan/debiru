//
//  BoardListCellView.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import SwiftUI

// MARK: - View

struct BoardListCellView: View {
    private let board: Board
    
    init(_ board: Board) {
        self.board = board
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text("/\(board.id)/")
                .font(.title)
            
            Text(board.title)
                .font(.headline)
        }
    }
}

// MARK: - Preview

struct BoardListViewCell_Previews: PreviewProvider {
    static var previews: some View {
        BoardListCellView(Board(
                            id: "f",
                            title: "Foobar",
                            description: "The board for all things foobar"))
    }
}
