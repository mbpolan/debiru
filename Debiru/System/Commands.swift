//
//  Commands.swift
//  Debiru
//
//  Created by Mike Polan on 4/3/21.
//

import SwiftUI

// MARK: - App Commands

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

// MARK: - Full Image View Commands

struct FullImageViewCommands: Commands {
    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Button("Original Size") {
                NotificationCenter.default.post(
                    name: .changeImageMode,
                    object: ImageScaleMode.original)
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Aspect Ratio") {
                NotificationCenter.default.post(
                    name: .changeImageMode,
                    object: ImageScaleMode.aspectRatio)
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button("Stretched") {
                NotificationCenter.default.post(
                    name: .changeImageMode,
                    object: ImageScaleMode.stretch)
            }
            .keyboardShortcut("3", modifiers: .command)
            
            Divider()
            
            Button("Reset Zoom") {
                NotificationCenter.default.post(
                    name: .resetZoom,
                    object: nil)
            }
            .keyboardShortcut("0", modifiers: .command)
            
            Button("Zoom In") {
                NotificationCenter.default.post(
                    name: .zoomIn,
                    object: nil)
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
                NotificationCenter.default.post(
                    name: .zoomOut,
                    object: nil)
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Divider()
        }
    }
}
