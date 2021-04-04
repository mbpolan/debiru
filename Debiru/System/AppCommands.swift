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
            Button("Go to Top") {
                NotificationCenter.default.post(name: .goToTop, object: nil)
            }
            .keyboardShortcut(.upArrow, modifiers: .command)
            
            Button("Go to Bottom") {
                NotificationCenter.default.post(name: .goToBottom, object: nil)
            }
            .keyboardShortcut(.downArrow, modifiers: .command)
            
            Divider()
            
            Button("Toggle Quick Search") {
                onShowQuickSearch()
            }
            .keyboardShortcut(.space, modifiers: .option)
            
            Button("Refresh Current View") {
                NotificationCenter.default.post(name: .refreshView, object: nil)
            }
            .keyboardShortcut(KeyEquivalent("r"), modifiers: .command)
            
            Button("Open In Browser") {
                NotificationCenter.default.post(name: .openInBrowser, object: nil)
            }
            .keyboardShortcut(KeyEquivalent("b"), modifiers: .command)
            
            Divider()
        }
    }
}
