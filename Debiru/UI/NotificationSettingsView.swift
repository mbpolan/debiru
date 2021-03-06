//
//  NotificationSettingsView.swift
//  Debiru
//
//  Created by Mike Polan on 4/16/21.
//

import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage(StorageKeys.notificationsEnabled) private var notificationsEnabled =
        UserDefaults.standard.notificationsEnabled()
    @AppStorage(StorageKeys.soundNotificationEnabled) private var soundNotificationEnabled =
        UserDefaults.standard.soundNotificationEnabled()
    
    var body: some View {
        let notificationsEnabledBinding = Binding<Bool>(
            get: { notificationsEnabled },
            set: { value in
                if value {
                    NotificationManager.shared?.requestPermission { result in
                        switch result {
                        case .success(let enabled):
                            self.notificationsEnabled = enabled
                        case .failure(let error):
                            print(error.localizedDescription)
                            break
                        }
                    }
                } else {
                    self.notificationsEnabled = false
                }
            })
        
        Form {
            Toggle("Enable desktop notifications", isOn: notificationsEnabledBinding)
            Toggle("Play a sound with each notification", isOn: $soundNotificationEnabled)
                .disabled(!notificationsEnabled)
        }
        .frame(width: 400, height: 120)
    }
}
