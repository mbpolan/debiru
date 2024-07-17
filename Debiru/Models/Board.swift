//
//  Board.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Foundation

struct Board: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let features: BoardFeatures
    
    var hasFeatures: Bool {
        return features.supportsCode
    }
}

struct BoardFeatures: Hashable, Codable {
    static let none = BoardFeatures(supportsCode: false)
    
    let supportsCode: Bool
}
