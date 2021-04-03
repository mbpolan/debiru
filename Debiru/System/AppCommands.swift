//
//  AppCommands.swift
//  Debiru
//
//  Created by Mike Polan on 4/3/21.
//

import SwiftUI

// MARK: - Commands

struct AppCommands: Commands {
    let onShowQuickSearch: () -> Void
    
    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Button("Toggle Quick Search") {
                onShowQuickSearch()
            }
            .keyboardShortcut(.space, modifiers: .option)
            
            Button("Refresh Current View") {
                NotificationCenter.default.post(name: .refreshView, object: nil)
            }
            .keyboardShortcut(KeyEquivalent("r"), modifiers: .command)
            
            Divider()
        }
    }
}
