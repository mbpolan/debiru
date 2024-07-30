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
    
    init() {
    }
    
    init(boards: [Board], downloads: [Download] = []) {
        self.boards = boards
        self.downloads = downloads
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        boards = try values.decode([Board].self, forKey: ._boards)
        downloads = try values.decode([Download].self, forKey: ._downloads)
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
    }
    
    enum CodingKeys: String, CodingKey {
        case _boards = "boards"
        case _downloads = "downloads"
    }
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("debiru.json")
    }
}

@Observable
class Download: Identifiable, Codable {
    var asset: Asset
    var state: State
    
    init(asset: Asset, state: State) {
        self.asset = asset
        self.state = state
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        asset = try values.decode(Asset.self, forKey: ._asset)
        state = try values.decode(State.self, forKey: ._state)
    }
    
    var id: String {
        return String(asset.id)
    }
    
    var filename: String {
        return "\(asset.filename)\(asset.extension)"
    }
    
    enum State: Codable {
        case downloading(completedBytes: Int64)
        case finished(on: Date, localURL: URL)
        case error(message: String)
    }
    
    enum CodingKeys: String, CodingKey {
        case _asset = "asset"
        case _state = "state"
    }
}
