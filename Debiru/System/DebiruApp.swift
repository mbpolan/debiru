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
    @AppStorage(StorageKeys.colorScheme) private var preferredColorScheme: PreferredColorScheme = .system
    @State private var appState: AppState = .init()
    private let dataProvider: DataProvider = FourChanDataProvider()
    
    /// Loads the list of boards available.
    private func loadBoards() async {
        do {
            appState.boards = try await dataProvider.getBoards()
        } catch {
            print(error);
        }
    }
    
    var body: some Scene {
        WindowGroup(for: UUID.self) { _ in
            ContentView()
                .environment(appState)
                .environment(\.deviceType, .defaultValue)
                .task {
                    await loadBoards()
                }
                .preferredColorScheme(colorScheme)
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
}
