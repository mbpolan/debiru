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
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
    }
}

extension Notification.Name {
    static let showBoard = Notification.Name("showBoard")
    static let showThread = Notification.Name("showThread")
}
