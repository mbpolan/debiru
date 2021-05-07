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
        }
        .padding(20)
    }
    
    private enum Tabs {
        case general
        case notifications
        case cache
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
