//
//  UserDefaults.swift
//  Debiru
//
//  Created by Mike Polan on 4/3/21.
//

import Foundation

extension UserDefaults {
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
}
