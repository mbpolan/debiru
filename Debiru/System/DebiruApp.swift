//
//  DebiruApp.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import SwiftUI

@main
struct DebiruApp: App {
    private var appState: AppState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            AppCommands(onShowQuickSearch: handleShowQuickSearch)
        }
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        
        WindowGroup {
            FullImageView()
                .environmentObject(appState)
                .handlesExternalEvents(preferring: Set(arrayLiteral: "image"), allowing: Set(arrayLiteral: "*"))
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        
        Settings {
            SettingsView()
        }
    }
    
    private func handleShowQuickSearch() {
        appState.quickSearchOpen = !appState.quickSearchOpen
    }
}

struct StorageKeys {
    static let defaultImageLocation = "defaultImageLocation"
    static let maxQuickSearchResults = "maxQuickSearchResults"
}
