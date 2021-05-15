//
//  Navigation.swift
//  Debiru
//
//  Created by Mike Polan on 5/14/21.
//

import SwiftUI

protocol Notifiable {
    func notify()
}

struct BoardDestination: Notifiable {
    let board: Board
    let filter: String?
    
    func notify() {
        NotificationCenter.default.post(name: .showBoard, object: self)
    }
}

enum ThreadDestination: Notifiable {
    case thread(Thread)
    case watchedThread(WatchedThread)
    
    func notify() {
        NotificationCenter.default.post(name: .showThread, object: self)
    }
}

struct WatchedThreadDestination: Notifiable {
    let thread: WatchedThread
    
    func notify() {
        NotificationCenter.default.post(name: .showThread, object: self)
    }
}

extension View {
    func onReceiveShowBoard(perform: @escaping(_: BoardDestination) -> Void) -> some View {
        return onReceive(NotificationCenter.default.publisher(for: .showBoard)) { event in
            if let board = event.object as? BoardDestination {
                perform(board)
            }
        }
    }
    
    func onReceiveShowThread(perform: @escaping(_: ThreadDestination) -> Void) -> some View {
        return onReceive(NotificationCenter.default.publisher(for: .showThread)) { event in
            if let thread = event.object as? ThreadDestination {
                perform(thread)
            }
        }
    }
}
