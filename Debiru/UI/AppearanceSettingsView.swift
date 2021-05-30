//
//  AppearanceSettingsView.swift
//  Debiru
//
//  Created by Mike Polan on 5/30/21.
//

import SwiftUI

// MARK: - View

struct AppearanceSettingsView: View {
    @AppStorage(StorageKeys.colorScheme) private var colorScheme: UserColorScheme = UserDefaults.standard.colorScheme()
    
    var body: some View {
        Form {
            VStack {
                Picker("Preferred color scheme", selection: $colorScheme) {
                    Text("System Default")
                        .tag(UserColorScheme.default)
                    Text("Dark")
                        .tag(UserColorScheme.dark)
                    Text("Light")
                        .tag(UserColorScheme.light)
                }
            }
        }
        .frame(width: 400, height: 80)
    }
}

// MARK: - Preview

struct AppearanceSettingsView_Preview: PreviewProvider {
    static var previews: some View {
        AppearanceSettingsView()
    }
}
