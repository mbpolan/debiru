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
}
