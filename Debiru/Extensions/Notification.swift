//
//  Notification.swift
//  Debiru
//
//  Created by Mike Polan on 4/3/21.
//

import Foundation

extension Notification.Name {
    static let showBoard = Notification.Name("showBoard")
    static let showThread = Notification.Name("showThread")
    static let showImage = Notification.Name("showImage")
    static let openInBrowser = Notification.Name("openInBrowser")
    static let refreshView = Notification.Name("refreshView")
    static let goBack = Notification.Name("goBack")
    static let goToTop = Notification.Name("goToTop")
    static let goToBottom = Notification.Name("goToBottom")
    static let saveAppState = Notification.Name("saveAppState")
    
    static let resetZoom = Notification.Name("resetZoom")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let changeImageMode = Notification.Name("changeImageMode")
}
