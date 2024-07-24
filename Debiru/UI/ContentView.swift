//
//  ContentView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

// MARK: - View

/// A view that displays the main content of the app.
struct ContentView: View {
    @State private var windowState: WindowState = .init()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            PhoneContentView()
                .environment(windowState)
        } else {
            DesktopContentView()
                .environment(windowState)
        }
    }
}

// MARK: - Phone View

/// A view that displays main app content intended for phones.
fileprivate struct PhoneContentView: View {
    @Environment(WindowState.self) var windowState
    
    var body: some View {
        @Bindable var windowState = windowState
        
        NavigationStack(path: $windowState.route) {
            SidebarView()
                .navigationDestination(for: ViewableItem.self) { item in
                    switch item {
                    case .board(let board):
                        BoardView(board: board)
                    case .thread(let board, let thread):
                        Text("Viewing: thread \(thread.id)")
                    }
                }
        }
        
    }
}

// MARK: - Desktop View

/// A view that displays main app content intended for desktops.
fileprivate struct DesktopContentView: View {
    @Environment(WindowState.self) var windowState
    
    var body: some View {
        @Bindable var windowState = windowState
        
        NavigationSplitView {
            SidebarView()
                .environment(windowState)
        } detail: {
            NavigationStack(path: $windowState.route) {
                Text("Select a board to view threads")
            }
            .navigationDestination(for: ViewableItem.self) { item in
                switch item {
                case .board(let board):
                    BoardView(board: board)
                case .thread(let board, let thread):
                    Text("Viewing: thread \(thread.id)")
                }
            }
        }
    }
}


// MARK: - Previews

#Preview {
    ContentView()
        .environment(AppState())
}
