//
//  MainView.swift
//  Debiru
//
//  Created by Mike Polan on 7/28/24.
//

import SwiftUI

// MARK: - Phone View

#if os(iOS)
typealias MainView = PhoneMainView
#else
typealias MainView = DesktopMainView
#endif

#if os(iOS)

/// A view that displays main app content intended for phones.
struct PhoneMainView: View {
    @Environment(AppState.self) var appState
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
                    case .downloads:
                        DownloadsView()
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    
                    Button {
                        windowState.clearNavigation()
                    } label: {
                        Label("", systemImage: "house")
                    }
                    
                    
                    Button {
                        windowState.navigateToDownloads()
                    } label: {
                        Label("", systemImage: "square.and.arrow.down.on.square")
                    }
                    .numberBadge(appState.newDownloads)
                    
                    Button {
                        windowState.navigateToSettings()
                    } label: {
                        Label("", systemImage: "gear")
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

#endif

// MARK: - Desktop View

#if os(macOS)

/// A view that displays main app content intended for desktops.
struct DesktopMainView: View {
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
                case .settings, .downloads:
                    EmptyView()
                }
            }
        }
    }
}

#endif

// MARK: - Previews

#Preview {
    MainView()
        .environment(AppState())
        .environment(WindowState())
}
