//
//  DownloadManager.swift
//  Debiru
//
//  Created by Mike Polan on 7/28/24.
//

import Foundation

/// A service that manages file and media downloads.
class DownloadManager: NSObject, URLSessionDownloadDelegate {
    private static var shared: DownloadManager?
    private static let dataProvider: DataProvider = FourChanDataProvider()
    private let assetManager: AssetManager
    private var appState: AppState
    private var downloads: [DownloadTask]
    
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
    /// track its progress.
    ///
    /// - Parameter asset: The asset to download.
    /// - Parameter localURL: The URL to write the data to.
    func addDownload(asset: Asset, to localURL: URL) {
        let remoteURL = DownloadManager.dataProvider.getURL(for: asset, variant: .original)
        
        self.appState.downloads.append(Download(asset: asset, state: .downloading(completedBytes: 0)))
        
        let task = URLSession.shared.downloadTask(with: remoteURL)
        task.delegate = self
        task.resume()
        
        self.downloads.append(DownloadTask(id: String(asset.id),
                                           remoteURL: remoteURL,
                                           localURL: localURL,
                                           totalBytes: asset.size,
                                           currentBytes: 0,
                                           task: task))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let idx = self.downloads.firstIndex(where: { $0.task == downloadTask }) else {
            return
        }
        
        let task = self.downloads.remove(at: idx)
        
        Task.detached {
            guard let download = self.appState.downloads.first(where: { $0.id == task.id }) else {
                return
            }
            
            var state: Download.State = .finished(on: .now, localURL: location)
            
            // copy the file to its final destination
            do {
                let data = try Data(contentsOf: location)
                let result = await self.assetManager.saveImage(fileName: download.asset.filename, data: data)
                switch result {
                case .success:
                    break
                case .denied:
                    state = .error(message: "Access to save image was denied")
                case .error(let message):
                    state = .error(message: message)
                }
                //            FileManager.default.createFile(atPath: task.localURL.path(), contents: data)
            } catch {
                state = .error(message: error.localizedDescription)
            }
            
            // update app state with the final state of the download
            DispatchQueue.main.async { [state] in
                download.state = state
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let task = self.downloads.first(where: { $0.task == downloadTask }) else {
            return
        }
        
        task.currentBytes += totalBytesWritten
        
        // update app state with current progress
        DispatchQueue.main.async { [weak self] in
            guard let download = self?.appState.downloads.first(where: { $0.id == task.id }) else {
                return
            }
            
            download.state = .downloading(completedBytes: task.currentBytes)
        }
    }
    
    private init(appState: AppState, assetManager: AssetManager) {
        self.appState = appState
        self.assetManager = assetManager
        self.downloads = []
    }
}

/// A task that tracks the progress of a single file download.
fileprivate class DownloadTask {
    let id: String
    let remoteURL: URL
    let localURL: URL
    let totalBytes: Int64
    var currentBytes: Int64
    let task: URLSessionDownloadTask
    
    init(id: String, remoteURL: URL, localURL: URL, totalBytes: Int64, currentBytes: Int64, task: URLSessionDownloadTask) {
        self.id = id
        self.remoteURL = remoteURL
        self.localURL = localURL
        self.totalBytes = totalBytes
        self.currentBytes = currentBytes
        self.task = task
    }
}
