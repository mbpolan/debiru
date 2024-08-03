//
//  AppState.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Observation
import Foundation

/// The global state of the app.
@Observable
class AppState: Codable {
    var boards: [Board] = []
    var downloads: [Download] = []
    var savedThreads: [SavedThread] = []
    var newDownloads: Int = 0
    
    init() {
    }
    
    init(boards: [Board], downloads: [Download] = [], savedThreads: [SavedThread] = []) {
        self.boards = boards
        self.downloads = downloads
        self.savedThreads = savedThreads
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        boards = try values.decode([Board].self, forKey: ._boards)
        downloads = try values.decode([Download].self, forKey: ._downloads)
        savedThreads = try values.decode([SavedThread].self, forKey: ._savedThreads)
        newDownloads = try values.decode(Int.self, forKey: ._newDownloads)
    }
    
    /// Loads the app state from persistence.
    ///
    /// - Returns: A Result containing the loaded app state or an error.
    static func load() async -> Result<AppState, Error> {
        let task = Task<AppState, Error> {
            let fileURL = try Self.fileURL()
            
            guard let data = try? Data(contentsOf: fileURL) else {
                return AppState()
            }
            
            return try JSONDecoder().decode(AppState.self, from: data)
        }
        
        do {
            return .success(try await task.value)
        } catch {
            return .failure(error)
        }
    }

    /// Saves the app state to a persistence store.
    ///
    /// - Returns: A result indicating success or an error.
    func save() async -> Result<Void, Error> {
        let task = Task {
            let data = try JSONEncoder().encode(self)
            try data.write(to: try Self.fileURL())
        }
        
        do {
            _ = try await task.value
            return .success(Void())
        } catch {
            return .failure(error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(boards, forKey: ._boards)
        try container.encode(downloads, forKey: ._downloads)
        try container.encode(savedThreads, forKey: ._savedThreads)
        try container.encode(newDownloads, forKey: ._newDownloads)
    }
    
    enum CodingKeys: String, CodingKey {
        case _boards = "boards"
        case _downloads = "downloads"
        case _newDownloads = "newDownloads"
        case _savedThreads = "savedThreads"
    }
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("debiru.json")
    }
}

/// An asset or resource that was requested to be downloaded.
@Observable
class Download: Identifiable, Codable {
    let id: UUID
    let resource: Resource
    var state: State
    let created: Date
    
    init(resource: Resource, state: State, created: Date, id: UUID = .init()) {
        self.id = id
        self.resource = resource
        self.state = state
        self.created = created
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(UUID.self, forKey: ._id)
        resource = try values.decode(Resource.self, forKey: ._resource)
        state = try values.decode(State.self, forKey: ._state)
        created = try values.decode(Date.self, forKey: ._created)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: ._id)
        try container.encode(resource, forKey: ._resource)
        try container.encode(state, forKey: ._state)
        try container.encode(created, forKey: ._date)
    }
    
    enum Resource: Codable {
        case asset(_ asset: Asset)
        case thread(_ boardID: String, _ threadID: Int)
    }
    
    enum State: Codable {
        case downloading(completedBytes: Int64)
        case finished(on: Date, localURL: URL?)
        case error(message: String)
    }
    
    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case _resource = "resource"
        case _state = "state"
        case _created  = "created"
        case _date = "date"
    }
}

// A thread that was downloaded by the user.
@Observable
class SavedThread: Identifiable, Codable {
    let original: Post
    let created: Date
    let localURL: URL
    
    init(original: Post, created: Date, localURL: URL) {
        self.original = original
        self.created = created
        self.localURL = localURL
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        original = try values.decode(Post.self, forKey: ._original)
        created = try values.decode(Date.self, forKey: ._created)
        localURL = try values.decode(URL.self, forKey: ._localURL)
    }
    
    var id: String {
        "\(original.boardId)-\(original.id)"
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(original, forKey: ._original)
        try container.encode(created, forKey: ._created)
        try container.encode(localURL, forKey: ._localURL)
    }
    
    enum CodingKeys: String, CodingKey {
        case _original = "original"
        case _created = "created"
        case _localURL = "localURL"
    }
}
