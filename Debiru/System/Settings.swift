//
//  Settings.swift
//  Debiru
//
//  Created by Mike Polan on 5/30/21.
//

import Foundation
import SwiftUI

// MARK: - Color Scheme

enum UserColorScheme: Int, Identifiable, CaseIterable {
    case `default`
    case dark
    case light
    
    var id: Int { rawValue }
    
    var identifier: ColorScheme? {
        switch self {
        case .default:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

// MARK: - Color Scheme

struct StorageKeys {
    static let colorScheme = "colorScheme"
    static let autoWatchReplied = "autoWatchReplied"
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
