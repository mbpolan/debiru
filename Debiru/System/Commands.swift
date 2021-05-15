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
            Button("Go Back") {
                NavigateNotification.back.notify()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)
            
            Button("Go to Top") {
                NavigateNotification.top.notify()
            }
            .keyboardShortcut(.upArrow, modifiers: .command)
            
            Button("Go to Bottom") {
                NavigateNotification.down.notify()
            }
            .keyboardShortcut(.downArrow, modifiers: .command)
            
            Divider()
            
            Button("Toggle Quick Search") {
                onShowQuickSearch()
            }
            .keyboardShortcut(.space, modifiers: .option)
            
            Button("Refresh Current View") {
                RefreshNotification().notify()
            }
            .keyboardShortcut(KeyEquivalent("r"), modifiers: .command)
            
            Button("Open In Browser") {
                OpenInBrowserNotification().notify()
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
                ImageModeNotification(mode: .original)
                    .notify()
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Aspect Ratio") {
                ImageModeNotification(mode: .aspectRatio)
                    .notify()
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button("Stretched") {
                ImageModeNotification(mode: .stretch)
                    .notify()
            }
            .keyboardShortcut("3", modifiers: .command)
            
            Divider()
            
            Button("Reset Zoom") {
                ImageZoomNotification
                    .zoomNormal
                    .notify()
            }
            .keyboardShortcut("0", modifiers: .command)
            
            Button("Zoom In") {
                ImageZoomNotification
                    .zoomIn
                    .notify()
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
                ImageZoomNotification
                    .zoomOut
                    .notify()
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Divider()
        }
    }
}
