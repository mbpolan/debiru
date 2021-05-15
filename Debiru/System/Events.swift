//
//  Navigation.swift
//  Debiru
//
//  Created by Mike Polan on 5/14/21.
//

import SwiftUI

protocol Notifiable {
    static var name: Notification.Name { get }
    func notify()
}

struct ShowImageNotification: Notifiable {
    static var name = Notification.Name("showImage")
    let asset: DownloadedAsset
    
    func notify() {
        NotificationCenter.default.post(name: ShowImageNotification.name, object: asset)
    }
}

struct ShowVideoNotification: Notifiable {
    static var name = Notification.Name("showVideo")
    let asset: Asset
    
    func notify() {
        NotificationCenter.default.post(name: ShowVideoNotification.name, object: asset)
    }
}

struct BoardDestination: Notifiable {
    static var name = Notification.Name("showBoard")
    let board: Board
    let filter: String?
    
    func notify() {
        NotificationCenter.default.post(name: BoardDestination.name, object: self)
    }
}

enum ThreadDestination: Notifiable {
    case thread(Thread)
    case watchedThread(WatchedThread)
    
    static var name: Notification.Name {
        return Notification.Name("showThread")
    }
    
    func notify() {
        NotificationCenter.default.post(name: ThreadDestination.name, object: self)
    }
}

extension View {
    func onNotification<T>(_ name: Notification.Name, perform: @escaping(_: T) -> Void) -> some View {
        return onReceive(NotificationCenter.default.publisher(for: name)) { event in
            if let data = event.object as? T {
                perform(data)
            } else {
                print("Invalid event data for notification \(name.rawValue)")
            }
        }
    }
    
    func onShowBoard(perform: @escaping(_: BoardDestination) -> Void) -> some View {
        return onNotification(BoardDestination.name, perform: perform)
    }
    
    func onShowThread(perform: @escaping(_: ThreadDestination) -> Void) -> some View {
        return onNotification(ThreadDestination.name, perform: perform)
    }
    
    func onShowImage(perform: @escaping(_: DownloadedAsset) -> Void) -> some View {
        return onNotification(ShowImageNotification.name, perform: perform)
    }
    
    func onShowVideo(perform: @escaping(_: Asset) -> Void) -> some View {
        return onNotification(ShowVideoNotification.name, perform: perform)
    }
}
