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
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        
        WindowGroup("Image") {
            FullImageView()
                .environmentObject(appState)
                .padding()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "image"), allowing: Set(arrayLiteral: "*"))
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .handlesExternalEvents(matching: Set(arrayLiteral: "image"))
        
        Settings {
            SettingsView()
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
