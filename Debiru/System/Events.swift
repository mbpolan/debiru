//
//  Navigation.swift
//  Debiru
//
//  Created by Mike Polan on 5/14/21.
//

import Combine
import SwiftUI

protocol Notifiable {
    static var name: Notification.Name { get }
    func notify()
}

struct ToggleSidebarNotification: Notifiable {
    static var name = Notification.Name("toggleSidebar")
    
    func notify() {
        NotificationCenter.default.post(name: ToggleSidebarNotification.name, object: nil)
    }
}

struct PersistAppStateNotification: Notifiable {
    static var name = Notification.Name("saveAppState")
    
    static var publisher: AnyPublisher<Notification, Never> {
        NotificationCenter
            .default
            .publisher(for: PersistAppStateNotification.name, object: nil)
            .eraseToAnyPublisher()
    }
    
    func notify() {
        NotificationCenter.default.post(name: PersistAppStateNotification.name, object: nil)
    }
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

struct OpenInBrowserNotification: Notifiable {
    static var name = Notification.Name("openInBrowser")
    
    func notify() {
        NotificationCenter.default.post(name: OpenInBrowserNotification.name, object: nil)
    }
}

struct RefreshNotification: Notifiable {
    static var name = Notification.Name("refreshView")
    
    func notify() {
        NotificationCenter.default.post(name: RefreshNotification.name, object: nil)
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

enum ImageZoomNotification: Notifiable {
    case zoomIn
    case zoomOut
    case zoomNormal
    
    static var name: Notification.Name {
        return Notification.Name("changeZoom")
    }
    
    func notify() {
        NotificationCenter.default.post(name: ImageZoomNotification.name, object: self)
    }
}

struct ImageModeNotification: Notifiable {
    static var name = Notification.Name("changeImageMode")
    let mode: ImageScaleMode
    
    func notify() {
        NotificationCenter.default.post(name: ImageModeNotification.name, object: mode)
    }
}

enum NavigateNotification: Notifiable {
    case top
    case down
    case back
    
    static var name: Notification.Name {
        return Notification.Name("navigate")
    }
    
    func notify() {
        NotificationCenter.default.post(name: NavigateNotification.name, object: self)
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
    
    func onNotification(_ name: Notification.Name, perform: @escaping() -> Void) -> some View {
        return onReceive(NotificationCenter.default.publisher(for: name)) { event in
            perform()
        }
    }
    
    func onToggleSidebar(perform: @escaping() -> Void) -> some View {
        return onNotification(ToggleSidebarNotification.name, perform: perform)
    }
    
    func onShowImage(perform: @escaping(_: DownloadedAsset) -> Void) -> some View {
        return onNotification(ShowImageNotification.name, perform: perform)
    }
    
    func onShowVideo(perform: @escaping(_: Asset) -> Void) -> some View {
        return onNotification(ShowVideoNotification.name, perform: perform)
    }
    
    func onOpenInBrowser(perform: @escaping() -> Void) -> some View {
        return onNotification(OpenInBrowserNotification.name, perform: perform)
    }
    
    func onRefreshView(perform: @escaping() -> Void) -> some View {
        return onNotification(RefreshNotification.name, perform: perform)
    }
    
    func onShowBoard(perform: @escaping(_: BoardDestination) -> Void) -> some View {
        return onNotification(BoardDestination.name, perform: perform)
    }
    
    func onShowThread(perform: @escaping(_: ThreadDestination) -> Void) -> some View {
        return onNotification(ThreadDestination.name, perform: perform)
    }
    
    func onImageZoom(perform: @escaping(_: ImageZoomNotification) -> Void) -> some View {
        return onNotification(ImageZoomNotification.name, perform: perform)
    }
    
    func onImageMode(perform: @escaping(_: ImageScaleMode) -> Void) -> some View {
        return onNotification(ImageModeNotification.name, perform: perform)
    }
    
    func onNavigate(perform: @escaping(_: NavigateNotification) -> Void) -> some View {
        return onNotification(NavigateNotification.name, perform: perform)
    }
}
