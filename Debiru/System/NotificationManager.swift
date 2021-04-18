//
//  Notifications.swift
//  Debiru
//
//  Created by Mike Polan on 4/16/21.
//

import SwiftUI
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static private(set) var shared: NotificationManager?
    
    @AppStorage(StorageKeys.notificationsEnabled) private var notificationsEnabled =
        UserDefaults.standard.notificationsEnabled()
    @AppStorage(StorageKeys.soundNotificationEnabled) private var soundNotificationEnabled =
        UserDefaults.standard.soundNotificationEnabled()
    
    private var appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared = self
    }
    
    func requestPermission(completion: @escaping(Result<Bool, Error>) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .provisional, .sound]) { ok, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(ok))
            }
        }
    }
    
    func updateApplicationBadge(withPostCount count: Int? = nil) {
        // use the provided count, or compute the total number of new posts if not
        let countNewPosts = count ?? appState.watchedThreads.reduce(0) { memo, watchedThread in
            return memo + watchedThread.totalNewPosts
        }
        
        NSApplication.shared.dockTile.badgeLabel = countNewPosts > 0 ? "\(countNewPosts)" : nil
    }
    
    func pushNewPostNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized,
                  (self?.notificationsEnabled ?? false) else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "New posts"
            content.body = "One or more of your watched threads have new replies."
            content.sound = (self?.soundNotificationEnabled ?? false) ? .default : nil
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to deliver notification: \(error.localizedDescription)")
                } else {
                    print("Notification posted")
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Received")
        completionHandler()
    }
}
