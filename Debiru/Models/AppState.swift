//
//  AppState.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Observation

/// The global state of the app.
@Observable
class AppState: Codable {
    var boards: [Board] = []
    
    init() {
        self.boards = []
    }
    
    init(boards: [Board]) {
        self.boards = boards
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        boards = try values.decode([Board].self, forKey: .boards)
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
