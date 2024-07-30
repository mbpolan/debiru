//
//  DebiruApp.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import SwiftUI

@main
struct DebiruApp: App {
    @Environment(\.colorScheme) private var systemColorScheme: ColorScheme
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    @AppStorage(StorageKeys.colorScheme) private var preferredColorScheme: PreferredColorScheme = .system
    @State private var appState: AppState = .init()
    private let assetManager: AssetManager = .init()
    private let dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some Scene {
        WindowGroup(for: UUID.self) { _ in
            ContentView()
                .environment(appState)
                .environment(\.deviceType, .defaultValue)
                .preferredColorScheme(colorScheme)
                .task({
                    await handleAppear()
                })
                .onChange(of: scenePhase, initial: false) { _, phase in
                    Task {
                        if phase == .inactive {
                            await persistState()
                        }
                    }
                }
                
        }
        #if os(macOS)
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        #endif
        
        #if os(macOS)
        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
        #endif
    }
    
    /// The preferred color scheme provided by the user.
    private var colorScheme: ColorScheme? {
        switch preferredColorScheme {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return nil
        }
    }
    
    /// Initializes the app state and dependent app services.
    ///
    /// This method should be called when the app starts up and before any user interaction takes place.
    private func handleAppear() async {
        await loadState()
        await loadBoards()
        
        DownloadManager.initialize(appState: appState, assetManager: assetManager)
    }
    
    /// Loads and initializes the app state.
    private func loadState() async {
        let result = await AppState.load()
        switch result {
        case .success(let state):
            self.appState = state
        case .failure(let error):
            print(error)
            break
        }
    }
    
    /// Persists the current app state.
    private func persistState() async {
        let result = await appState.save()
        switch result {
        case .success(_):
            break
        case .failure(let error):
            print(error)
        }
    }
    
    /// Loads the list of boards available.
    private func loadBoards() async {
        do {
            appState.boards = try await dataProvider.getBoards()
        } catch {
            print(error);
        }
    }
}
