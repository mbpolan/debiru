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
            
            FilterSettingsView()
                .tabItem {
                    Label("Filters", systemImage: "doc.plaintext")
                }
                .tag(Tabs.filters)
        }
        .padding(20)
    }
    
    private enum Tabs {
        case general
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
