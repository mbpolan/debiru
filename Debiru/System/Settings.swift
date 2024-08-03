//
//  Settings.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import Foundation

enum PreferredColorScheme: String, RawRepresentable {
    case dark = "dark"
    case light = "light"
    case system = "system"
}

struct StorageKeys {
    static let colorScheme = "colorScheme"
    static let defaultImageLocation = "defaultImageLocation"
    static let defaultDataLocation = "defaultDataLocation"
}

struct Settings {
    /// The default location where images should be saved.
    ///
    /// - Returns: A URL for the default image storage location.
    static var defaultImageLocation: URL {
        FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
    }
    
    /// The default location where data should be saved.
    ///
    /// - Returns: A URL for the default data storage location.
    static var defaultDataLocation: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Debiru", conformingTo: .directory)
    }
}
