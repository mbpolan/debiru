//
//  DebiruApp.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Combine
import SwiftUI

@main
struct DebiruApp: App {
    private var appState: AppState
    private let saveAppStatePublisher = NotificationCenter.default.publisher(for: .saveAppState)
    private var cancellables: Set<AnyCancellable> = Set()
    
    init() {
        // load saved app state if it exists, or default to our initial state otherwise
        let state = StateLoader.shared.load()
        switch state {
        case .success(let data):
            self.appState = data ?? AppState()
        case .failure(let error):
            print("Failed to load state: \(error.localizedDescription)")
            self.appState = AppState()
        }
        
        cancellables.insert(saveAppStatePublisher
                                .receive(on: DispatchQueue.global(qos: .background))
                                .sink(receiveValue: handleSaveAppState))
    }
    
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
    
    private func handleSaveAppState(notification: Notification) {
        let result = StateLoader.shared.save(state: appState)
        switch result {
        case .failure(let error):
            print("Failed to save state: \(error.localizedDescription)")
        default:
            break
        }
    }
}

struct StorageKeys {
    static let refreshTimeout = "refreshTimeout"
    static let defaultImageLocation = "defaultImageLocation"
    static let maxQuickSearchResults = "maxQuickSearchResults"
    static let groupImagesByBoard = "groupImagesByBoard"
}
