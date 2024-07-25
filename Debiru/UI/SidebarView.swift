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
        List(appState.boards, id: \.id, selection: self.currentBoard) { board in
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
    
    private var currentBoard: Binding<String?> {
        return Binding<String?>(
            get: {
                switch windowState.currentItem {
                case .board(let boardId):
                    return boardId
                case .thread(let boardId, _):
                    return boardId
                case .none:
                    return nil
                }
            },
            set: {
                if let boardId = $0 {
                    windowState.route = NavigationPath([ViewableItem.board(boardId: boardId)])
                } else {
                    windowState.route = NavigationPath()
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
