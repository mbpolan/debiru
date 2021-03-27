//
//  GeneralSettingsView.swift
//  Debiru
//
//  Created by Mike Polan on 3/27/21.
//

import SwiftUI

// MARK: - View

struct GeneralSettingsView: View {
    @AppStorage(StorageKeys.defaultImageLocation) private var defaultImageLocation: URL =
        FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
    
    var body: some View {
        Form {
            LazyVGrid(columns: [
                GridItem(.fixed(200)),
                GridItem(.fixed(100), spacing: 0.0, alignment: .trailing),
            ], alignment: .leading) {
                Text("Default location to save images")
                
                Button(action: handleChooseSaveLocation) {
                    Text(defaultImageLocation.lastPathComponent)
                }
                .help(defaultImageLocation
                        .absoluteString
                        .replacingOccurrences(of: "file://", with: ""))
            }
        }
        .frame(width: 400, height: 50)
    }
    
    private func handleChooseSaveLocation() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        
        if panel.runModal() == .OK,
           let url = panel.url {
            defaultImageLocation = url
        }
    }
}

// MARK: - Preview

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
