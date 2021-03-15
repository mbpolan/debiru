//
//  Board.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Foundation

struct Boards: Codable {
    let boards: [Board]
}

struct Board: Codable, Hashable {
    let id: String
    let title: String
    let description: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "board"
        case title
        case description = "meta_description"
    }
}
