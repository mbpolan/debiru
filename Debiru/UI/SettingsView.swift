//
//  SettingsView.swift
//  Debiru
//
//  Created by Mike Polan on 3/27/21.
//

import SwiftUI

// MARK: - View

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
                .tag(Tabs.appearance)
            
            NotificationSettingsView()
                .tabItem {
                    Label("Notifications", systemImage: "exclamationmark.bubble")
                }
                .tag(Tabs.notifications)
            
            CacheSettingsView()
                .tabItem {
                    Label("Cache", systemImage: "internaldrive")
                }
                .tag(Tabs.cache)
            
#if os(macOS)
            FilterSettingsView()
                .tabItem {
                    Label("Filters", systemImage: "doc.plaintext")
                }
                .tag(Tabs.filters)
#endif
        }
        .padding(20)
    }
    
    private enum Tabs {
        case general
        case appearance
        case notifications
        case cache
        case filters
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
