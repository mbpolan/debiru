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
    @State private var appState: AppState = .init()
    private let dataProvider: DataProvider = FourChanDataProvider()
    
    init() {
        // check and request permissions for data
        switch DataManager.shared.checkSaveDirectory() {
        case .failure(let error):
            print(error.localizedDescription)
        default:
            break
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
    
    var body: some Scene {
        WindowGroup(for: UUID.self) { _ in
            ContentView()
                .environment(appState)
                .task {
                    await loadBoards()
                }
        }
#if os(macOS)
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
#endif
    }
}
