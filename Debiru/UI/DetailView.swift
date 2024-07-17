//
//  DetailView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

// MARK: - View

struct DetailView: View {
    @Environment(WindowState.self) private var windowState
    
    var body: some View {
        switch windowState.currentItem {
        case .board(let board):
            BoardView(board: board)
        case .thread(let board, let thread):
            Text("Viewing: thread \(thread.id)")
        case .none:
            LandingView()
        }
    }
}

// MARK: - Previews

#Preview {
    DetailView()
        .environment(AppState())
        .environment(WindowState())
}
