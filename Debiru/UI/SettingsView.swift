//
//  SettingsView.swift
//  Debiru
//
//  Created by Mike Polan on 7/28/24.
//

import SwiftUI

// MARK: - View

#if os(iOS)
typealias SettingsView = PhoneSettingsView
#else
typealias SettingsView = DesktopSettingsView
#endif

/// A view that presents app settings for desktop form factors.
struct DesktopSettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .scenePadding()
        }
    }
}

/// A view that presents app settings suitable for phone form factors.
struct PhoneSettingsView: View {
    var body: some View {
        Group {
            GeneralSettingsView()
        }
        .navigationTitle("Settings")
    }
}

/// A view that displays general app settings.
fileprivate struct GeneralSettingsView: View {
    @State private var viewModel: GeneralSettingsViewModel = .init()
    @AppStorage(StorageKeys.colorScheme) var colorScheme: PreferredColorScheme = .system
    @AppStorage(StorageKeys.defaultImageLocation) var defaultImageLocation: URL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
    
    var body: some View {
        Form {
            Picker("Color scheme", selection: $colorScheme) {
                Text("Light")
                    .tag(PreferredColorScheme.light)
                
                Text("Dark")
                    .tag(PreferredColorScheme.dark)
                
                Text("System")
                    .tag(PreferredColorScheme.system)
            }
            
            // changing the image save location is not supported on iOS
            #if os(macOS)
            HStack {
                Text("Default image location")
                Button(action: handleShowFileImporter) {
                    Text(defaultImageLocation.description.replacingOccurrences(of: "file://", with: ""))
                }
            }
            #endif
        }
        .fileImporter(isPresented: $viewModel.fileImporterShown, allowedContentTypes: [.directory], onCompletion: self.handleFileImporterCompleted)
    }
    
    private func handleShowFileImporter() {
        viewModel.fileImporterShown = true
    }
    
    private func handleFileImporterCompleted(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            defaultImageLocation = url
        case .failure(let error):
            // TODO
            break
        }
    }
}

// MARK: - View Model

@Observable
fileprivate class GeneralSettingsViewModel {
    var fileImporterShown: Bool = false
    var colorScheme: ColorScheme = .system
    
    enum ColorScheme: Equatable {
        case dark
        case light
        case system
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
}
