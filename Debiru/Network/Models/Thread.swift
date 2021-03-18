//
//  Thread.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

struct Thread: Identifiable, Hashable {
    let id: Int
    let poster: String
    let subject: String?
    let content: String?
    let sticky: Bool
    let closed: Bool
    let attachment: Asset?
}
