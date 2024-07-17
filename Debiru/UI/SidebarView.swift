//
//  SidebarView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

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
    }
    
    private var currentBoard: Binding<Board?> {
        return Binding<Board?>(
            get: { windowState.currentBoard },
            set: { windowState.currentBoard = $0 }
        )
    }
}

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
