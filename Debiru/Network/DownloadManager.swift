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
        
        let download = Download(asset: asset, state: .downloading(completedBytes: 0), created: .now)
        self.appState.downloads.append(download)
        
        let task = URLSession.shared.downloadTask(with: remoteURL)
        task.delegate = self
        task.resume()
        
        self.downloads.append(DownloadTask(id: download.id,
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
        guard let download = self.appState.downloads.first(where: { $0.id == task.id }) else {
            return
        }
        
        Task {
            let state: Download.State
            
            // copy the file to its final destination
            do {
                let data = try Data(contentsOf: location)
                let result = await self.assetManager.saveImage(filename: download.asset.fullName, data: data)
                
                switch result {
                case .success(let location):
                    state = .finished(on: .now, localURL: location)
                case .denied:
                    state = .error(message: "Access to save image was denied")
                case .error(let message):
                    state = .error(message: message)
                }
            } catch {
                state = .error(message: error.localizedDescription)
            }
            
            // update app state with the final state of the download
            await self.updateDownload(task.id, state: state)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let task = self.downloads.first(where: { $0.task == downloadTask }) else {
            print("Cannot find download for task \(downloadTask.taskIdentifier)")
            return
        }
        
        task.currentBytes = totalBytesWritten
        
        Task {
            await self.updateDownload(task.id, state: .downloading(completedBytes: task.currentBytes))
        }
    }
    
    @MainActor
    private func updateDownload(_ id: UUID, state: Download.State) {
        guard let idx = self.appState.downloads.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // replace the download in the array to force a state update
        let download = self.appState.downloads[idx]
        self.appState.downloads[idx] = Download(asset: download.asset, state: state, created: download.created, id: download.id)
    }
    
    private init(appState: AppState, assetManager: AssetManager) {
        self.appState = appState
        self.assetManager = assetManager
        self.downloads = []
    }
}

/// A task that tracks the progress of a single file download.
fileprivate class DownloadTask {
    let id: UUID
    let remoteURL: URL
    let localURL: URL
    let totalBytes: Int64
    var currentBytes: Int64
    let task: URLSessionDownloadTask
    
    init(id: UUID, remoteURL: URL, localURL: URL, totalBytes: Int64, currentBytes: Int64, task: URLSessionDownloadTask) {
        self.id = id
        self.remoteURL = remoteURL
        self.localURL = localURL
        self.totalBytes = totalBytes
        self.currentBytes = currentBytes
        self.task = task
    }
}
