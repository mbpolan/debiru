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
    @AppStorage(StorageKeys.colorScheme) private var colorScheme: UserColorScheme = UserDefaults.standard.colorScheme()
    
    private var appState: AppState
    private let notificationManager: NotificationManager
    private let threadWatcher: ThreadWatcher
    private var cancellables: Set<AnyCancellable> = Set()
    
    init() {
        // check and request permissions for data
        switch DataManager.shared.checkSaveDirectory() {
        case .failure(let error):
            print(error.localizedDescription)
        default:
            break
        }
        
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
        
        PersistAppStateNotification.publisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: handleSaveAppState)
            .store(in: &cancellables)
    }
    
    var body: some Scene {
        // main content window
        
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme.identifier)
        }
        .commands {
            AppCommands(onShowQuickSearch: handleShowQuickSearch)
        }
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        
        // image viewer window

        WindowGroup {
            FullImageView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme.identifier)
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
                .preferredColorScheme(colorScheme.identifier)
                .handlesExternalEvents(preferring: Set(arrayLiteral: "webVideo"), allowing: Set(arrayLiteral: "webVideo"))
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .handlesExternalEvents(matching: Set(arrayLiteral: "webVideo"))
        
        Settings {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme.identifier)
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
