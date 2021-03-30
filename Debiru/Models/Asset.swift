//
//  Asset.swift
//  Debiru
//
//  Created by Mike Polan on 3/17/21.
//

struct Asset: Identifiable, Hashable, Equatable {
    let id: Int
    let boardId: String
    let width: Int
    let height: Int
    let thumbnailWidth: Int
    let thumbnailHeight: Int
    let filename: String
    let `extension`: String
    
    var fullName: String {
        return "\(filename)\(`extension`)"
    }
}
