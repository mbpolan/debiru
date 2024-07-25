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
        Group {
            if horizontalSizeClass == .compact {
                PhoneContentView()
                    .environment(windowState)
            } else {
                DesktopContentView()
                    .environment(windowState)
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            return handleOpenURL(url)
        })
    }
    
    private func handleOpenURL(_ url: URL) -> OpenURLAction.Result {
        let str = url.absoluteString
        
        // internal link to a board or post
        if str.starts(with: "//boards.4channel.org/") {
            let path = str
                    .replacingOccurrences(of: "//boards.4channel.org/", with: "")
                    .trimmingCharacters(in: ["/"])
                    .split(separator: "/")
            
            // if there is only one path segment, it's most likely a cross-board link
            if path.count == 1 {
                windowState.navigate(boardId: String(path[0]))
                return .handled
            } else {
                print("Unsupported URL: \(str)")
                return .systemAction
            }
        }
        
        
        return .systemAction
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
                    case .board(let boardId):
                        BoardView(boardId: boardId)
                    case .thread(let boardId, let threadId):
                        ThreadView(boardId: boardId, threadId: threadId)
                    case .asset(let asset):
                        AssetView(asset: asset)
                    }
                }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    windowState.clearNavigation()
                } label: {
                    Label("", systemImage: "house")
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
                case .board(let boardId):
                    BoardView(boardId: boardId)
                case .thread(let boardId, let threadId):
                    ThreadView(boardId: boardId, threadId: threadId)
                case .asset(let asset):
                    AssetView(asset: asset)
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
