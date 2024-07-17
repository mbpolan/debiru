//
//  ContentView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

/// A view that displays the main content of the app.
struct ContentView: View {
    @State private var windowState: WindowState = .init()
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environment(windowState)
        } detail: {
            
        }
    }
}
