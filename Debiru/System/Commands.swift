//
//  Commands.swift
//  Debiru
//
//  Created by Mike Polan on 8/3/24.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Refresh Notification

/// A notification that gets published when data should be refreshed on a given view.
struct RefreshNotification {
    static var name = Notification.Name("refresh")
    
    static var publisher: AnyPublisher<Notification, Never> {
        NotificationCenter
            .default
            .publisher(for: Self.name, object: nil)
            .eraseToAnyPublisher()
    }
    
    func notify() {
        NotificationCenter.default.post(name: Self.name, object: nil)
    }
}

// MARK: - Extensions

extension View {
    func onNotification(_ name: Notification.Name, perform: @escaping() -> Void) -> some View {
        return onReceive(NotificationCenter.default.publisher(for: name)) { event in
            perform()
        }
    }
    
    func onRefresh(_ perform: @escaping() -> Void) -> some View {
        return onNotification(RefreshNotification.name, perform: perform)
    }
}
