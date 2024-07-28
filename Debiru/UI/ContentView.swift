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
    
    var body: some View {
        Group {
            MainView()
                .environment(windowState)
        }
        .environment(\.openURL, OpenURLAction { url in
            return handleOpenURL(url)
        })
    }
    
    private func handleOpenURL(_ url: URL) -> OpenURLAction.Result {
        let str = url.absoluteString
        
        // urls beginning with / generally link to boards, posts or replies
        // urls beginning with # are links to replies in the same thread
        if str.starts(with: "/") {
            // normalize the path by removing the site's domain name
            let path = str
                .replacingOccurrences(of: "//boards.4channel.org/", with: "")
                .split(separator: "/")
            
            // if there is only one path segment, it's a link to another board
            // otherwise, examine each path segment and determine where it's linking to
            if path.count == 1 {
                windowState.navigate(boardId: String(path[0]))
                return .handled
            } else if path.count == 3 && path[1] == "thread" {
                let boardId = String(path[0])
                
                // the thread id may additionally link to a specific post, ie: 12345#98765
                var threadId = String(path[2])
                if let idx = threadId.firstIndex(of: "#") {
                    threadId = String(threadId[..<idx])
                }
                
                if let threadId = Int(threadId) {
                    windowState.navigate(boardId: boardId, threadId: Int(threadId))
                    return .handled
                } else {
                    print("Invalid thread ID in URL: \(str)")
                    return .systemAction
                }
            } else {
                print("Unsupported URL: \(str)")
                return .systemAction
            }
        } else if str.starts(with: "#") {
            // TODO
            return .handled
        }
        
        
        return .systemAction
    }
}

// MARK: - Phone View

#if os(iOS)

/// A view that displays main app content intended for phones.
fileprivate struct MainView: View {
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

#endif

// MARK: - Desktop View

#if os(macOS)

/// A view that displays main app content intended for desktops.
fileprivate struct MainView: View {
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

#endif


// MARK: - Previews

#Preview {
    ContentView()
        .environment(AppState())
}
