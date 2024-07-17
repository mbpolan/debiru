//
//  SidebarView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

// MARK: - View

/// A view that displays a list of selectable boards.
struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(WindowState.self) private var windowState
    
    var body: some View {
        List(appState.boards, id: \.self, selection: self.currentBoard) { board in
            HStack {
                Text("/\(board.id)/")
                    .bold()
                Spacer()
                Text(board.title)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Boards")
    }
    
    private var currentBoard: Binding<Board?> {
        return Binding<Board?>(
            get: {
                switch windowState.currentItem {
                case .board(let board):
                    return board
                case .thread(let board, _):
                    return board
                case .none:
                    return nil
                }
            },
            set: {
                if let board = $0 {
                    windowState.currentItem = .board(board)
                } else {
                    windowState.currentItem = nil
                }
            }
        )
    }
}

// MARK: - Previews

#Preview {
    SidebarView()
        .environment(AppState(
            boards: [Board(id: "a",
                           title: "Animals",
                           description: "Animals and stuff",
                           features: .none)
            ]))
        .environment(WindowState())
}
