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
    private var tasks: [DownloadTask]
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
    /// track its progress.
    ///
    /// - Parameter asset: The asset to download.
    /// - Parameter localURL: The URL to write the data to.
    func addDownload(asset: Asset, to localURL: URL) {
        let remoteURL = DownloadManager.dataProvider.getURL(for: asset.id, boardID: asset.boardId, extension: asset.extension, variant: .original)
        
        let download = Download(resource: .asset(asset), state: .downloading(completedBytes: 0), created: .now, totalSize: asset.size)
        self.appState.downloads.append(download)
        
        let task = URLSession.shared.downloadTask(with: remoteURL)
        task.delegate = self
        task.resume()
        
        self.tasks.append(DownloadTask(id: download.id,
                                           parentID: nil,
                                           type: .asset,
                                           remoteURL: remoteURL,
                                           localURL: localURL,
                                           totalBytes: asset.size,
                                           currentBytes: 0,
                                           task: task,
                                           subTasks: []))
        self.appState.newDownloads += 1
    }
    
    /// Adds a thread to download.
    ///
    /// - Parameter boardId: The ID of the board the thread is in.
    /// - Parameter threadId: The ID of the thread.
    /// - Parameter localURL: The URL to the directory where thread data will be written to.
    func addDownload(boardId: String, threadId: Int, to localURL: URL) {
        let remoteURL = Self.dataProvider.getDataURL(for: boardId, threadID: threadId)
        
        let download = Download(resource: .thread(boardId, threadId), state: .downloading(completedBytes: 0), created: .now, totalSize: nil)
        self.appState.downloads.append(download)
        
        let task = URLSession.shared.downloadTask(with: remoteURL)
        task.delegate = self
        task.resume()
        
        self.tasks.append(DownloadTask(id: download.id,
                                           parentID: nil,
                                           type: .thread,
                                           remoteURL: remoteURL,
                                           localURL: localURL,
                                           totalBytes: 0,
                                           currentBytes: 0,
                                           task: task,
                                           subTasks: []))
        self.appState.newDownloads += 1
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let source: URL
        do {
            source = try self.moveToLanding(location)
        } catch {
            print("ERROR: failed to copy to landing: \(error)")
            
            guard let task = self.tasks.first(where: { $0.task == downloadTask }) else {
                return
            }
            
            guard var download = self.appState.downloads.first(where: { $0.id == (task.parentID ?? task.id) }) else {
                return
            }
            
            Task {
                await self.updateDownload(task.id, state: .error(message: error.localizedDescription))
            }
            
            return
        }
        
        Task {
            guard let taskIdx = self.tasks.firstIndex(where: { $0.task == downloadTask }) else {
                return
            }
            
            let task = self.tasks[taskIdx]
            
            guard var download = self.appState.downloads.first(where: { $0.id == (task.parentID ?? task.id) }) else {
                return
            }
            
            guard let response = downloadTask.response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    return
            }
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: source.path()))
                
                // determine where to write data to based on the parent task type
                switch download.resource {
                case .asset(let asset):
                    // individual assets are saved to the image location on the platform
                    let result = await self.assetManager.saveImage(filename: asset.fullName, data: data)
                    
                    let state: Download.State
                    switch result {
                    case .success(let location):
                        state = .finished(on: .now, localURL: location)
                    case .denied:
                        state = .error(message: "Access to save image was denied")
                    case .error(let message):
                        state = .error(message: message)
                    }
                    
                    self.tasks.remove(at: taskIdx)
                    await self.updateDownload(task.id, state: state)
                    
                case .thread(let boardID, let threadID):
                    switch task.type {
                    case .asset:
                        _ = await self.assetManager.saveThreadImage(directory: boardID, threadID: threadID, filename: task.localURL.lastPathComponent, data: data)
                        self.tasks.remove(at: taskIdx)
                        
                        if let parentTask = self.tasks.first(where: { $0.id == task.parentID }),
                           let subTaskIdx = parentTask.subTasks.firstIndex(of: task.id) {
                            
                            parentTask.subTasks.remove(at: subTaskIdx)
                            
                            if parentTask.subTasks.isEmpty {
                                await self.updateDownload(parentTask.id, state: .finished(on: .now, localURL: nil))
                            } else {
                                parentTask.currentBytes += task.totalBytes
                                await self.updateDownload(parentTask.id, state: .downloading(completedBytes: parentTask.currentBytes))
                            }
                        } else {
                            print("WARN: could not find parent task \(task.parentID)")
                        }
                        
                    case .thread:
                        _ = await self.assetManager.saveThread(directory: boardID, filename: "\(threadID).json", data: data)
                        
                        let assets = try Self.dataProvider.getAssetURLs(for: boardID, threadData: data)
                        if !assets.isEmpty {
                            let total = assets.reduce(0, { memo, item in
                                return memo + item.size
                            })
                            
                            let subTasks = assets.map { entry in
                                let task = URLSession.shared.downloadTask(with: entry.url)
                                task.delegate = self
                                task.resume()
                                
                                let localURL = location.deletingLastPathComponent()
                                    .appendingPathComponent("\(threadID)", conformingTo: .directory)
                                    .appendingPathComponent("\(entry.id)\(entry.fileExtension)", conformingTo: .fileURL)
                                
                                return DownloadTask(id: .init(),
                                             parentID: download.id,
                                             type: .asset,
                                             remoteURL: entry.url,
                                             localURL: localURL,
                                             totalBytes: entry.size,
                                             currentBytes: 0,
                                             task: task,
                                             subTasks: [])
                            }
                            
                            self.tasks.append(contentsOf: subTasks)
                            task.subTasks.append(contentsOf: subTasks.map { $0.id })
                            
                            await self.updateDownload(task.id, state: .downloading(completedBytes: 0), totalSize: total)
                        } else {
                            self.tasks.remove(at: taskIdx)
                            await self.updateDownload(task.id, state: .finished(on: .now, localURL: nil))
                        }
                    }
                    
                }
            } catch {
                print("ERROR: failed to download \(task.id): \(error.localizedDescription)")
                await self.updateDownload(task.id, state: .error(message: error.localizedDescription))
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let task = self.tasks.first(where: { $0.task == downloadTask }) else {
            print("Cannot find download for task \(downloadTask.taskIdentifier)")
            return
        }
        
        task.currentBytes = totalBytesWritten
        
        Task {
            await self.updateDownload(task.id, state: .downloading(completedBytes: task.currentBytes))
        }
    }
    
    @MainActor
    private func updateDownload(_ id: UUID, state: Download.State, totalSize: Int64? = nil) {
        guard let idx = self.appState.downloads.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // replace the download in the array to force a state update
        let download = self.appState.downloads[idx]
        self.appState.downloads[idx] = Download(resource: download.resource, 
                                                state: state,
                                                created: download.created,
                                                totalSize: totalSize ?? download.totalSize,
                                                id: download.id)
    }
    
    private func moveToLanding(_ from: URL) throws -> URL {
        let to = self.landingURL.appendingPathComponent(from.lastPathComponent, conformingTo: .fileURL)
        try FileManager.default.copyItem(at: from, to: URL(fileURLWithPath: to.absoluteString))
        
        return to
    }
    
    private init(appState: AppState, assetManager: AssetManager) {
        self.appState = appState
        self.assetManager = assetManager
        self.tasks = []
        
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

/// A task that tracks the progress of a single file download.
fileprivate class DownloadTask {
    let id: UUID
    let parentID: UUID?
    let type: DownloadType
    let remoteURL: URL
    let localURL: URL
    let totalBytes: Int64
    var currentBytes: Int64
    let task: URLSessionDownloadTask
    var subTasks: [UUID]
    
    init(id: UUID, parentID: UUID?, type: DownloadType, remoteURL: URL, localURL: URL, totalBytes: Int64, currentBytes: Int64,
         task: URLSessionDownloadTask, subTasks: [UUID]) {
        self.id = id
        self.parentID = parentID
        self.type = type
        self.remoteURL = remoteURL
        self.localURL = localURL
        self.totalBytes = totalBytes
        self.currentBytes = currentBytes
        self.task = task
        self.subTasks = subTasks
    }
    
    enum DownloadType {
        case asset
        case thread
    }
}
