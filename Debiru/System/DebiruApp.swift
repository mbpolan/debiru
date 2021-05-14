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
    private let notificationManager: NotificationManager
    private let saveAppStatePublisher = NotificationCenter.default.publisher(for: .saveAppState)
    private let threadWatcher: ThreadWatcher
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
        
        // prepare for notifications
        self.notificationManager = NotificationManager(appState: appState)
        
        // start watching threads for updates
        self.threadWatcher = ThreadWatcher(appState: appState)
        self.threadWatcher.start()
        
        cancellables.insert(saveAppStatePublisher
                                .receive(on: DispatchQueue.global(qos: .background))
                                .sink(receiveValue: handleSaveAppState))
    }
    
    var body: some Scene {
        // main content window
        
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            AppCommands(onShowQuickSearch: handleShowQuickSearch)
        }
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        
        // image viewer window

        WindowGroup {
            FullImageView()
                .environmentObject(appState)
                .handlesExternalEvents(preferring: Set(arrayLiteral: "image"), allowing: Set(arrayLiteral: "image"))
        }
        .commands {
            FullImageViewCommands()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .handlesExternalEvents(matching: Set(arrayLiteral: "image"))
        
        // web video window

        WindowGroup {
            WebVideoView()
                .environmentObject(appState)
                .handlesExternalEvents(preferring: Set(arrayLiteral: "webVideo"), allowing: Set(arrayLiteral: "webVideo"))
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .handlesExternalEvents(matching: Set(arrayLiteral: "webVideo"))
        
        Settings {
            SettingsView()
                .environmentObject(appState)
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
    static let notificationsEnabled = "notificationsEnabled"
    static let soundNotificationEnabled = "soundNotificationEnabled"
    static let maximumCacheSize = "maximumCacheSize"
    static let cacheEnabled = "cacheEnabled"
    static let limitCacheEnabled = "limitCacheEnabled"
    static let boardWordFilters = "boardWordFilters"
}
