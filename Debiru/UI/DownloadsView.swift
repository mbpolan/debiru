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

/// A view that displays and allows managing asset downloads for phone form factors.
struct PhoneDownloadsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    private static let dateFormatter = RelativeDateTimeFormatter()
    
    var body: some View {
        List(appState.downloads) { download in
            HStack(alignment: .center) {
                switch download.state {
                case .downloading(let completedBytes):
                    Image(systemName: "arrow.down.circle.dotted")
                    Text(assetName(download.asset))
                        .padding(.trailing, 25)
                    
                    Spacer()
                    
                    ProgressView(value: Float(completedBytes), total: Float(download.asset.size))
                        .progressViewStyle(LinearProgressViewStyle())
                    
                case .finished(let on, let localURL):
                    Group {
                        Image(systemName: "checkmark.circle")
                        Text(assetName(download.asset))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(PhoneDownloadsView.dateFormatter.localizedString(for: on, relativeTo: .now))
                    }
                    .onTapGesture { handleOpenAsset(localURL) }
                    
                case .error(let message):
                    Image(systemName: "exclamationmark.triangle")
                    Text(assetName(download.asset))
                    
                }
            }
        }
        .navigationTitle("Downloads")
    }
    
    private func assetName(_ asset: Asset) -> String {
        return "\(asset.filename)\(asset.extension)"
    }
    
    private func handleOpenAsset(_ url: URL) {
        openURL(url)
    }
}

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
                                         state: .downloading(completedBytes: 130403333)),
                                Download(asset: .init(id: 678905,
                                                      boardId: "g",
                                                      width: 100,
                                                      height: 100,
                                                      thumbnailWidth: 100,
                                                      thumbnailHeight: 100,
                                                      filename: "foo",
                                                      extension: ".jpg",
                                                      fileType: .image, size: 160403333),
                                         state: .finished(on: .now, localURL: URL(string: "https://google.pl")!)),
                                Download(asset: .init(id: 92020232,
                                                      boardId: "g",
                                                      width: 100,
                                                      height: 100,
                                                      thumbnailWidth: 100,
                                                      thumbnailHeight: 100,
                                                      filename: "foo",
                                                      extension: ".jpg",
                                                      fileType: .image, size: 160403333),
                                         state: .error(message: "The image no longer exists")),
                              ]))
}
