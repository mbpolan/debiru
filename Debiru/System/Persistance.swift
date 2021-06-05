//
//  Persistance.swift
//  Debiru
//
//  Created by Mike Polan on 4/9/21.
//

import Foundation

// MARK: - State Loader

struct StateLoader {
    static let shared: StateLoader = StateLoader()
    private let appDirectory: String = "Debiru"
    private let currentVersion: UInt = 1
    private let valid: Bool
    
    func save(state: AppState) -> Result<Bool, Error> {
        guard valid else {
            return .failure(LoadError.invalid("Loader is not in valid state"))
        }
        
        do {
            let json = try JSONEncoder().encode(convertToSnapshot(state))
            try json.write(to: getURL(create: true))
            
            return .success(true)
        } catch (let error) {
            return .failure(error)
        }
    }
    
    func load() -> Result<AppState?, Error> {
        guard valid else {
            return .failure(LoadError.invalid("Loader is not in valid state"))
        }
        
        do {
            let url = try getURL(create: false)
            let data = try Data(contentsOf: url)
            
            let state = convertFromSnapshot(
                try JSONDecoder().decode(Snapshot.self, from: data))
            
            // load board filters from user defaults
            if let boardFiltersData = UserDefaults.standard.data(forKey: StorageKeys.boardWordFilters) {
                state.boardFilters = try JSONDecoder().decode(
                    [String: [OrderedFilter]].self,
                    from: boardFiltersData)
            }
            
            return .success(state)
        } catch (let error) {
            return .failure(error)
        }
    }
    
    private init() {
        do {
            var isDirectory: ObjCBool = true
            
            // get the url for the application support directory
            let url = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
                .appendingPathComponent(appDirectory, isDirectory: true)
            
            // if our app's subdirectory does not exist, create it upfront
            if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(
                    at: url, withIntermediateDirectories: false,
                    attributes: nil)
            }
            
            valid = true
        } catch (let error) {
            print("Failed to initialize state loader: \(error.localizedDescription)")
            valid = false
        }
    }
    
    private func getURL(create: Bool) throws -> URL {
        return try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: create)
            .appendingPathComponent(appDirectory, isDirectory: true)
            .appendingPathComponent("state.json")
    }
    
    private func convertToSnapshot(_ state: AppState) -> Snapshot {
        return Snapshot(
            version: currentVersion,
            watchedThreads: state.watchedThreads.map { watchedThread in
                return WatchedThreadSnapshot(
                    lastPostId: watchedThread.lastPostId,
                    currentLastPostId: watchedThread.currentLastPostId,
                    totalNewPosts: watchedThread.totalNewPosts,
                    nowArchived: watchedThread.nowArchived,
                    nowDeleted: watchedThread.nowDeleted,
                    thread: ThreadSnapshot(
                        boardId: watchedThread.thread.boardId,
                        id: watchedThread.thread.id,
                        subject: watchedThread.thread.subject,
                        content: watchedThread.thread.content,
                        author: watchedThread.thread.author,
                        date: watchedThread.thread.date))
            })
    }
    
    private func convertFromSnapshot(_ snapshot: Snapshot) -> AppState {
        let appState = AppState()
        
        appState.watchedThreads = snapshot.watchedThreads.map { watchedThread in
            return WatchedThread(
                thread: Thread(
                    id: watchedThread.thread.id,
                    boardId: watchedThread.thread.boardId,
                    author: watchedThread.thread.author,
                    date: watchedThread.thread.date,
                    subject: watchedThread.thread.subject,
                    content: watchedThread.thread.content,
                    sticky: false,
                    closed: false,
                    spoileredImage: false,
                    attachment: nil,
                    statistics: .unknown),
                lastPostId: watchedThread.lastPostId,
                currentLastPostId: watchedThread.currentLastPostId,
                totalNewPosts: watchedThread.totalNewPosts,
                nowArchived: watchedThread.nowDeleted,
                nowDeleted: watchedThread.nowDeleted)
        }
        
        return appState
    }
}

// MARK: - Extensions

extension StateLoader {
    enum LoadError: Error {
        case invalid(String)
    }
}

// MARK: - Internal Models

fileprivate struct ThreadSnapshot: Codable {
    let boardId: String
    let id: Int
    let subject: String?
    let content: String?
    let author: User
    let date: Date
}

fileprivate struct WatchedThreadSnapshot: Codable {
    let lastPostId: Int
    let currentLastPostId: Int
    let totalNewPosts: Int
    let nowArchived: Bool
    let nowDeleted: Bool
    let thread: ThreadSnapshot
}

fileprivate struct Snapshot: Codable {
    let version: UInt
    let watchedThreads: [WatchedThreadSnapshot]
}
