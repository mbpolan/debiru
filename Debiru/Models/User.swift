//
//  User.swift
//  Debiru
//
//  Created by Mike Polan on 3/28/21.
//

struct User: Hashable, Codable {
    let name: String?
    let tripCode: String?
    let isSecure: Bool
}
