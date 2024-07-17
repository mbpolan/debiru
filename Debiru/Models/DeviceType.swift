//
//  DeviceType.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

/// Enumeration of supported platform targets.
enum DeviceTypeKey: EnvironmentKey {
    #if os(iOS)
    static let defaultValue: DeviceTypeKey = .iOS
    #else
    static let defaultValue: DeviceTypeKey = .macOS
    #endif
    
    case iOS
    case macOS
}

extension EnvironmentValues {
    var deviceType: DeviceTypeKey {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }
}
