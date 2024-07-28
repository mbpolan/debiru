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
    @State private var viewModel: ViewModel = .init()
    
    var body: some View {
        List(boards, id: \.id, selection: self.currentBoard) { board in
            HStack {
                Text("/\(board.id)/")
                    .bold()
                Spacer()
                Text(board.title)
            }
        }
        .navigationTitle("Boards")
        .listStyle(.sidebar)
        #if os(iOS)
        .searchable(text: $viewModel.filter)
        #endif
    }
    
    private var boards: [Board] {
        if viewModel.filter == "" {
            return appState.boards
        }
        
        return appState.boards.filter { board in
            if viewModel.filter.starts(with: "/") {
                return board.id.contains(viewModel.filter.trimmingCharacters(in: ["/"]))
            } else {
                return board.title.localizedCaseInsensitiveContains(viewModel.filter)
            }
        }
    }
    
    private var currentBoard: Binding<String?> {
        return Binding<String?>(
            get: {
                switch windowState.currentItem {
                case .board(let boardId):
                    return boardId
                case .thread(let boardId, _):
                    return boardId
                case .asset(let asset):
                    return asset.boardId
                case .none, .settings:
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

// MARK: - View Model

@Observable
fileprivate class ViewModel {
    var filter: String = ""
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
