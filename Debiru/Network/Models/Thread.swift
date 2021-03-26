//
//  Thread.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

import Foundation

struct Thread: Identifiable, Hashable {
    let id: Int
    let boardId: String
    let poster: String
    let date: Date
    let subject: String?
    let content: String?
    let sticky: Bool
    let closed: Bool
    let attachment: Asset?
}
