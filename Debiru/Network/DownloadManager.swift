//
//  DownloadManager.swift
//  Debiru
//
//  Created by Mike Polan on 7/28/24.
//

import Foundation

/// A service that manages file and media downloads.
class DownloadManager {
    private static var shared: DownloadManager?
    private static let dataProvider: DataProvider = FourChanDataProvider()
    private let assetManager: AssetManager
    private var appState: AppState
    private let landingURL: URL
    
    /// Initializes the download manager.
    ///
    /// - Parameter appState: The app state to back the download manager.
    static func initialize(appState: AppState, assetManager: AssetManager) {
        DownloadManager.shared = .init(appState: appState, assetManager: assetManager)
    }
    
    /// Returns the shared instance of this service.
    ///
    /// You must call `initialize(_: AppState)` first to prepare an instance.
    ///
    /// - Returns: An instance of this class.
    static func instance() -> DownloadManager {
        guard let shared = DownloadManager.shared else {
            fatalError("download manager is not initialized!")
        }
        
        return shared
    }
    
    /// Adds an asset to download.
    ///
    /// This method will add an asset to the download manager, and update the app state to
    /// track its progress. This method does not block.
    ///
    /// - Parameter asset: The asset to download.
    /// - Parameter localURL: The URL to write the data to.
    func download(asset: Asset, to localURL: URL) async {
        let remoteURL = DownloadManager.dataProvider.getURL(for: asset.id, boardID: asset.boardId, extension: asset.extension, variant: .original)
        
        let download = Download(resource: .asset(asset), 
                                state: .downloading(completedBytes: 0),
                                created: .now,
                                totalSize: asset.size)
        
        Task { @MainActor in
            self.appState.downloads.append(download)
            self.appState.newDownloads += 1
        }
        
        let state = await withDownload(remoteURL: remoteURL) { data in
            return await self.assetManager.saveImage(filename: asset.fullName, data: data)
        }
        
        Task { @MainActor in
            download.state = state
        }
    }
    
    /// Adds a thread to download.
    ///
    /// - Parameter boardID: The ID of the board the thread is in.
    /// - Parameter threadID: The ID of the thread.
    /// - Parameter localURL: The URL to the directory where thread data will be written to.
    func download(boardID: String, threadID: Int, to localURL: URL) async {
        let remoteURL = Self.dataProvider.getDataURL(for: boardID, threadID: threadID)
        
        let download = Download(resource: .thread(boardID, threadID),
                                state: .downloading(completedBytes: 0), 
                                created: .now,
                                totalSize: nil)
        
        Task { @MainActor in
            self.appState.downloads.append(download)
            self.appState.newDownloads += 1
        }
        
        let threadState = await withDownload(remoteURL: remoteURL) { data in
            return await self.assetManager.saveThread(directory: boardID, filename: "\(threadID).json", data: data)
        }
        
        let overallState = await downloadThreadAssets(boardID: boardID, threadID: threadID, threadState: threadState, download: download)
        
        Task { @MainActor in
            download.state = overallState
            
            switch overallState {
            case .finished(let when, let localURL):
                // read the downloaded data, extract the original post and save the thread in app state
                // FIXME: maybe not reading the raw data multiple times would help?
                if let localURL = localURL,
                   let threadData = try? Data(contentsOf: localURL),
                   let original = try Self.dataProvider.getOriginalPost(for: boardID, threadID: threadID, fromthreadData: threadData) {
                    
                    appState.savedThreads.append(SavedThread(original: original, created: when, localURL: localURL))
                }
                
            default:
                break
            }
        }
    }
    
    /// Downloads all assets in a thread.
    ///
    /// - Parameter boardID: The ID of the board the thread is in.
    /// - Parameter threadID: The ID of the thread to download.
    /// - Parameter threadState: The download state of the thread data itself.
    /// - Parameter download: The download data.
    ///
    /// - Returns: The overall state of downloading all assets.
    private func downloadThreadAssets(boardID: String, threadID: Int, threadState: Download.State, download: Download) async -> Download.State {
        let threadDataURL: URL
        
        switch threadState {
        case .finished(_, let localURL):
            guard let url = localURL else {
                return threadState
            }
            
            threadDataURL = url
        default:
            return threadState
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: threadDataURL.path))
            let assets = try Self.dataProvider.getAssetURLs(for: boardID, threadData: data)
            
            if assets.isEmpty {
                return .finished(on: .now, localURL: threadDataURL)
            }
            
            // compute the total size of all assets in the thread
            Task { @MainActor in
                download.totalSize = assets.reduce(0, { memo, item in
                    return memo + item.size
                })
            }
            
            // create a separate task to download each asset
            let results = try await withThrowingTaskGroup(of: Download.State.self) { group in
                for asset in assets {
                    group.addTask {
                        return await self.withDownload(remoteURL: asset.url) { data in
                            return await self.assetManager.saveThreadImage(directory: boardID,
                                                                           threadID: threadID,
                                                                           filename: "\(asset.id)\(asset.fileExtension)",
                                                                           data: data)
                        }
                    }
                }
                    
                var results: [Download.State] = []
                for try await result in group {
                    results.append(result)
                }
                
                return results
            }
            
            var errors = 0
            for result in results {
                switch result {
                case .error(_):
                    errors += 1
                default:
                    break
                }
            }
            
            if errors > 0 {
                return .error(message: "Unable to save \(errors) out of \(assets.count) thread images")
            }
            
            return .finished(on: .now, localURL: threadDataURL)
        } catch {
            return .error(message: error.localizedDescription)
        }
    }
    
    /// Performs an action to download data and checks the result of the download.
    ///
    /// - Parameter remoteURL: The URL of the asset to download.
    /// - Parameter action: The closure to execute to process the downloaded data.
    ///
    /// - Returns: The download state.
    private func withDownload(remoteURL: URL, action: (_ data: Data) async throws -> AssetResult) async -> Download.State {
        let state: Download.State
        
        do {
            let (url, response) = try await URLSession.shared.download(from: remoteURL)
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let data = try Data(contentsOf: url)
                    
                    let result = try await action(data)
                    switch result {
                    case .success(let location):
                        state = .finished(on: .now, localURL: location)
                    case .denied:
                        state = .error(message: "Access was not allowed to complete download")
                    case .error(let error):
                        state = .error(message: error)
                    }
                } else {
                    state = .error(message: "Unsuccessful response from server: \(response.statusCode)")
                }
            } else {
                state = .error(message: "Invalid response from server")
            }
        } catch {
            state = .error(message: error.localizedDescription)
        }
        
        return state
    }
    
    /// Moves a file to the app's landing zone.
    ///
    /// - Parameter from: The URL of the file.
    ///
    /// - Returns: The URL of the file in the landing zone.
    private func moveToLanding(_ from: URL) throws -> URL {
        let to = self.landingURL.appendingPathComponent(from.lastPathComponent, conformingTo: .fileURL)
        try FileManager.default.copyItem(at: from, to: URL(fileURLWithPath: to.absoluteString))
        
        return to
    }
    
    private init(appState: AppState, assetManager: AssetManager) {
        self.appState = appState
        self.assetManager = assetManager
        
        guard let url = URL(string: NSHomeDirectory()) else {
            fatalError("Cannot establish landing URL")
        }
        
        self.landingURL = url.appendingPathComponent("landing", conformingTo: .directory)
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: self.landingURL.path()), withIntermediateDirectories: true)
        } catch {
            fatalError("Cannot create landing directory: \(error.localizedDescription)")
        }
    }
}
