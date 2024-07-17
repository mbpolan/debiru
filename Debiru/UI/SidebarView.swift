//
//  SidebarView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List(appState.boards) { board in
            HStack {
                Text("/\(board.id)/")
                    .bold()
                Spacer()
                Text(board.title)
            }
        }
    }
}

#Preview {
    SidebarView()
        .environmentObject(AppState(
            currentItem: nil,
            boards: [Board(id: "a",
                           title: "Animals",
                           description: "Animals and stuff",
                           features: .none)
            ]))
}
