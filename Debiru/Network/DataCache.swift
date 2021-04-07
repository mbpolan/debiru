//
//  DataCache.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import Foundation

typealias DataCache = NSCache<CacheKey, CacheData>

class CacheKey: NSObject {
    private let key: String
    
    init(_ key: String) {
        self.key = key
    }
    
    override var hash: Int {
        return self.key.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CacheKey else { return false }
        
        return self.key == other.key
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
