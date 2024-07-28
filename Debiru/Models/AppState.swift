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
        
        boards = try values.decode([Board].self, forKey: .boards)
    }
}

@Observable
class Download: Identifiable {
    var asset: Asset
    var state: State
    
    init(asset: Asset, state: State) {
        self.asset = asset
        self.state = state
    }
    
    var id: String {
        return "\(asset.boardId)-\(asset.id)"
    }
    
    enum State {
        case downloading(completedBytes: Int64)
        case finished(on: Date, localURL: URL)
        case error(message: String)
    }
}

extension AppState {
    private enum CodingKeys: String, CodingKey {
        case boards
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boards, forKey: .boards)
    }
}
