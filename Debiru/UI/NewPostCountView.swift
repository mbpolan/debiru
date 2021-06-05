//
//  NewPostCountView.swift
//  Debiru
//
//  Created by Mike Polan on 6/4/21.
//

import SwiftUI

// MARK: - View

struct NewPostCountView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack {
            if appState.newPostCount > 0 {
                Image(systemName: "exclamationmark.bubble.fill")
                    .foregroundColor(.blue)
                    .help("\(appState.newPostCount) new post(s)")
                    .contextMenu {
                        Button("Mark as Read", action: handleMarkAllRead)
                    }
            }
        }
    }
    
    private func handleMarkAllRead() {
        appState.watchedThreads = appState.watchedThreads.map { watchedThread in
            return WatchedThread(
                thread: watchedThread.thread,
                lastPostId: watchedThread.currentLastPostId,
                currentLastPostId: watchedThread.currentLastPostId,
                totalNewPosts: 0,
                nowArchived: watchedThread.nowArchived,
                nowDeleted: watchedThread.nowDeleted)
        }
        
        PersistAppStateNotification().notify()
    }
}

// MARK: - Preview

struct NewPostCountView_Preview: PreviewProvider {
    static let appState = AppState()
    
    static var previews: some View {
        NewPostCountView()
            .environmentObject(appState)
    }
}
