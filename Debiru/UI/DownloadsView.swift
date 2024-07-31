//
//  DownloadsView.swift
//  Debiru
//
//  Created by Mike Polan on 7/28/24.
//

import SwiftUI

// MARK: - View

#if os(iOS)
typealias DownloadsView = PhoneDownloadsView
#else
typealias DownloadsView = DesktopDownloadsView
#endif

// MARK: - Phone View

#if os(iOS)

/// A view that displays and allows managing asset downloads for phone form factors.
struct PhoneDownloadsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @State private var viewModel: ViewModel = .init()
    private static let dateFormatter = RelativeDateTimeFormatter()
    
    var body: some View {
        List(appState.downloads) { download in
            switch download.state {
            case .downloading(let completedBytes):
                HStack(alignment: .center) {
                    Image(systemName: "arrow.down.circle.dotted")
                    Text(assetName(download.asset))
                        .padding(.trailing, 25)
                    
                    Spacer()
                    
                    ProgressView(value: Float(completedBytes), total: Float(download.asset.size))
                        .progressViewStyle(LinearProgressViewStyle())
                }
                
            case .finished(let on, let localURL):
                HStack(alignment: .center) {
                    Image(systemName: "checkmark.circle")
                    Text(assetName(download.asset))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(PhoneDownloadsView.dateFormatter.localizedString(for: on, relativeTo: .now))
                }
                .onTapGesture { handleOpenAsset(localURL) }
                
            case .error(let message):
                HStack(alignment: .center) {
                    Image(systemName: "exclamationmark.triangle")
                        .help(message)
                    
                    Text(assetName(download.asset))
                }
                .onTapGesture { viewModel.popoverShown = true }
                .popover(isPresented: $viewModel.popoverShown) {
                    Text(message)
                        .padding()
                }
            }
        }
        .navigationTitle("Downloads")
    }
    
    /// Returns the filename to display for an asset.
    ///
    /// - Returns: A filename to show to the user.
    private func assetName(_ asset: Asset) -> String {
        return "\(asset.filename)\(asset.extension)"
    }
    
    /// Handles an action to view the asset.
    ///
    /// - Parameter url: The local URL of the asset.
    private func handleOpenAsset(_ url: URL?) {
        if let url = url {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Phone View Model

@Observable
fileprivate class ViewModel {
    var popoverShown: Bool = false
}

#elseif os(macOS)

// MARK: - Desktop View

/// A view that presents a table of assets currently known to the download manager.
struct DesktopDownloadsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    private static let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    private static let relativeDateFormatter = RelativeDateTimeFormatter()
    
    var body: some View {
        Table(appState.downloads) {
            TableColumn("File", value: \.filename)
            
            TableColumn("Date") { item in
                Text(Self.dateFormatter.string(for: item.created) ?? "Unknown")
                    .help(Self.relativeDateFormatter.string(for: item.created) ?? "Unknown")
            }
            
            TableColumn("Size") { item in
                Text("\(item.asset.size) bytes")
            }
            
            TableColumn("Status") { item in
                switch item.state {
                case .finished(_, _):
                    Text("Complete")
                    
                case .error(let message):
                    Text(message)
                        .help(message)
                    
                case .downloading(let completedBytes):
                    ProgressView(value: Float(completedBytes), total: Float(item.asset.size))
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
        }
        .contextMenu(forSelectionType: UUID.self, menu: { items in
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting(downloadLocation(items))
            }
            .disabled(!canRevealInFinder(items))
        }, primaryAction: handleOpenFile)
    }
    
    /// Handles opening the local file associated with an asset.
    ///
    /// - Parameter items: The UUID (singleton set) of the table row item.
    private func handleOpenFile(_ items: Set<UUID>) {
        let locations = downloadLocation(items)
        guard let url = locations.first else {
            return
        }
        
        NSWorkspace.shared.open(url)
    }
    
    /// Determines if an asset should be viewable in Finder.
    ///
    /// - Parameter items: The UUID (singleton set) of the table row item.
    ///
    /// - Returns: Boolean true if viewable, false if not.
    private func canRevealInFinder(_ items: Set<UUID>) -> Bool {
        guard let download = self.appState.downloads.first(where: { $0.id == items.first }) else {
            return false
        }
        
        switch download.state {
        case .finished(_, let location):
            return location != nil
        default:
            return false
        }
    }
    
    /// Returns the local URL of a downloaded asset.
    ///
    /// - Parameter items: The UUID (singleton set) of the table row item.
    ///
    /// - Returns: A singleton array containing the local URL, or an empty array if the URL cannot be determined.
    private func downloadLocation(_ items: Set<UUID>) -> [URL] {
        guard let download = self.appState.downloads.first(where: { $0.id == items.first }) else {
            return []
        }
        
        switch download.state {
        case .finished(_, let location):
            if let location = location {
                return [location]
            } else {
                return []
            }
        default:
            return []
        }
    }
}

#endif

// MARK: - Previews

#Preview {
    DownloadsView()
        .environment(AppState(boards: [],
                              downloads: [
                                Download(asset: .init(id: 123456,
                                                      boardId: "g",
                                                      width: 100,
                                                      height: 100,
                                                      thumbnailWidth: 100,
                                                      thumbnailHeight: 100,
                                                      filename: "foo",
                                                      extension: ".jpg",
                                                      fileType: .image, size: 160403333),
                                         state: .downloading(completedBytes: 130403333),
                                         created: .now),
                                Download(asset: .init(id: 678905,
                                                      boardId: "g",
                                                      width: 100,
                                                      height: 100,
                                                      thumbnailWidth: 100,
                                                      thumbnailHeight: 100,
                                                      filename: "foo",
                                                      extension: ".jpg",
                                                      fileType: .image, size: 160403333),
                                         state: .finished(on: .now, localURL: URL(string: "https://google.pl")!),
                                         created: .now),
                                Download(asset: .init(id: 92020232,
                                                      boardId: "g",
                                                      width: 100,
                                                      height: 100,
                                                      thumbnailWidth: 100,
                                                      thumbnailHeight: 100,
                                                      filename: "foo",
                                                      extension: ".jpg",
                                                      fileType: .image, size: 160403333),
                                         state: .error(message: "The image no longer exists"),
                                         created: .now),
                              ]))
}
