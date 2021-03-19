//
//  DataCache.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import Foundation

typealias DataCache = NSCache<CacheKey, CacheData>

class CacheKey {
    private let key: String
    
    init(_ key: String) {
        self.key = key
    }
}

class CacheData {
    let data: Data
    
    init(_ data: Data){
        self.data = data
    }
}

extension DataCache {
    func set(_ key: String, value: Data) {
        setObject(CacheData(value), forKey: CacheKey(key))
    }
    
    func get(forKey key: String) -> Data? {
        return object(forKey: CacheKey(key))?.data
    }
}
