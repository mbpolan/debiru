//
//  DataProvider.swift
//  Debiru
//
//  Created by Mike Polan on 3/14/21.
//

import Combine
import Foundation

protocol DataProvider {
    
    func getBoards(_ completion: @escaping(_: Result<[Board], Error>) -> Void) -> AnyCancellable?
}

enum NetworkError: Error {
    case invalidResponse(String)
}
