//
//  Notifications.swift
//  Debiru
//
//  Created by Mike Polan on 4/16/21.
//

import SwiftUI
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @AppStorage(StorageKeys.notificationsEnabled) private var notificationsEnabled =
        UserDefaults.standard.notificationsEnabled()
    
    func prepare() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission(completion: @escaping(Result<Bool, Error>) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .provisional]) { ok, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(ok))
            }
        }
    }
    
    func pushNewPostNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized,
                  (self?.notificationsEnabled ?? false) else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "New posts"
            content.body = "One or more of your watched threads have new replies."
            
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
