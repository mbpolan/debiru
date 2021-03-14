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
    
    private enum CodingKeys: String, CodingKey {
        case id = "board"
        case title
    }
}
