//
//  DataCache.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import Combine
import Foundation

// MARK: - Cache

class DataCache: NSObject, NSCacheDelegate {
    static let shared = DataCache()
    
    private let cache: NSCache<CacheKey, CacheData> = NSCache()
    private var enabled: Bool = true
    private var count: Int = 0
    private var cost: Int = 0
    
    let statisticsSubject: PassthroughSubject<Statistics, Never> = PassthroughSubject()
    
    override init() {
        super.init()
        
        cache.delegate = self
        self.configureFromUserDefaults()
    }
    
    var statistics: Statistics {
        return Statistics(count: count, cost: cost)
    }
    
    func setEnabled(_ enabled: Bool) {
        if !enabled {
            clear()
        }
        
        self.enabled = enabled
    }
    
    func updateMaximumCost(_ cost: Int) {
        cache.totalCostLimit = cost
    }
    
    func set(_ key: String, value: Data) {
        guard enabled else { return }
        
        cache.setObject(
            CacheData(value),
            forKey: CacheKey(key),
            cost: value.count)
        
        count += 1
        cost += value.count
        publishUpdate()
    }
    
    func clear() {
        cache.removeAllObjects()
        count = 0
        cost = 0
        
        publishUpdate()
    }
    
    func get(forKey key: String) -> Data? {
        return cache.object(forKey: CacheKey(key))?.data
    }
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        if let data = obj as? CacheData {
            cost -= data.data.count
        }
        
        count -= 1
        publishUpdate()
    }
    
    private func publishUpdate() {
        statisticsSubject.send(self.statistics)
    }
    
    private func configureFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        enabled = defaults.bool(forKey: StorageKeys.cacheEnabled, defaultValue: defaults.cacheEnabled())
        
        // apply cache cost limits if enabled
        if enabled {
            if defaults.bool(forKey: StorageKeys.limitCacheEnabled, defaultValue: defaults.limitCacheEnabled()) {
                // convert user defaults into bytes
                cache.totalCostLimit = (defaults.integer(
                                            forKey: StorageKeys.maximumCacheSize,
                                            defaultValue: defaults.maximumCacheSize())) * 1024 * 1024
            } else {
                // no limit specified
                cache.totalCostLimit = 0
            }
        }
    }
}

// MARK: - Extension

extension DataCache {
    struct Statistics {
        let count: Int
        let cost: Int
        
        static var empty: Statistics = .init(count: 0, cost: 0)
    }
    
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
}
