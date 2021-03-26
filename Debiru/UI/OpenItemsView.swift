//
//  OpenItemsView.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import SwiftUI

// MARK: - View

struct OpenItemsView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack {
            if appState.openItems.isEmpty {
                Spacer()
                Text("No open boards or threads")
                Spacer()
            } else {
                List(appState.openItems, id: \.self) { item in
                    switch item {
                    case .board(let board):
                        BoardListCellView(board)
                    case .thread(_, let thread):
                        ThreadListCellView(thread)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

struct OpenItemsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenItemsView()
            .environmentObject(AppState(
                                currentItem: nil,
                                boards: [],
                                openItems: []))
    }
}
