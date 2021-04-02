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

struct AppCommands: Commands {
    let onShowQuickSearch: () -> Void
    
    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Button("Toggle Quick Search") {
                onShowQuickSearch()
            }
            .keyboardShortcut(.space, modifiers: .option)
            
            Divider()
        }
    }
}

extension UserDefaults {
    func defaultImageLocation() -> URL {
        self.url(forKey: StorageKeys.defaultImageLocation) ??
            FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
    }
}

struct StorageKeys {
    static let defaultImageLocation = "defaultImageLocation"
}

extension Notification.Name {
    static let showBoard = Notification.Name("showBoard")
    static let showThread = Notification.Name("showThread")
    static let showImage = Notification.Name("showImage")
}
