//
//  Settings.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import Foundation

struct StorageKeys {
    static let colorScheme = "colorScheme"
    static let autoWatchReplied = "autoWatchReplied"
    static let showRelativeDates = "showRelativeDates"
    static let refreshTimeout = "refreshTimeout"
    static let defaultImageLocation = "defaultImageLocation"
    static let maxQuickSearchResults = "maxQuickSearchResults"
    static let groupImagesByBoard = "groupImagesByBoard"
    static let notificationsEnabled = "notificationsEnabled"
    static let soundNotificationEnabled = "soundNotificationEnabled"
    static let maximumCacheSize = "maximumCacheSize"
    static let cacheEnabled = "cacheEnabled"
    static let limitCacheEnabled = "limitCacheEnabled"
    static let boardWordFilters = "boardWordFilters"
    
    static let bookmarkSaveDirectory = "bookmarkSaveDirectory"
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        return contains(key: key) ? bool(forKey: key) : defaultValue
    }
    
    func integer(forKey key: String, defaultValue: Int) -> Int {
        return contains(key: key) ? integer(forKey: key) : defaultValue
    }
    
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
    
    func autoWatchReplied() -> Bool {
        return true
    }
    
    func showRelativeDates() -> Bool {
        return false
    }
    
    /// Returns the default auto-refresh timeout.
    ///
    /// - Returns: The timeout, in seconds.
    func refreshTimeout() -> Int {
        return 10
    }
    
    /// Returns the default location to save images.
    ///
    /// - Returns: A URL.
    func defaultImageLocation() -> URL {
        self.url(forKey: StorageKeys.defaultImageLocation) ??
            FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
    }
    
    /// Returns the maximum amount of quick search results to display.
    ///
    /// - Returns: The maximum result set size.
    func maxQuickSearchResults() -> Int {
        return 5
    }
    
    /// Returns whether images should be saved in directories corresponding to ther boards.
    ///
    /// - Returns: true if enabled, false if not.
    func groupImagesByBoard() -> Bool {
        return false
    }
    
    /// Returns whether local notifications are enabled.
    ///
    /// - Returns: true if enabled, false if not.
    func notificationsEnabled() -> Bool {
        return false
    }
    
    /// Returns whether to play a sound with notifications.
    ///
    /// - Returns: true to play a sound, false to not do so.
    func soundNotificationEnabled() -> Bool {
        return false
    }
    
    /// Returns the maximum amount of data to store in cache.
    ///
    /// - Returns: number of megabytes to cache at most (or zero for no limit).
    func maximumCacheSize() -> Int {
        return 5
    }
    
    /// Returns whether data caching is enabled or not.
    ///
    /// - Returns: true if enabled, false if not.
    func cacheEnabled() -> Bool {
        return true
    }
    
    /// Returns if data caching is restricted to a specific size.
    ///
    /// - Returns: true if enabled, false if not.
    func limitCacheEnabled() -> Bool {
        return true
    }
}
