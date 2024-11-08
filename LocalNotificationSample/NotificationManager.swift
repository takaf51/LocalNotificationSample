//
//  NotificationManager.swift
//  LocalNotificationSample
//
//  Created by Taka on 2024-11-08.
//

import Foundation
import UserNotifications

@MainActor
@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    let notificationCenter = UNUserNotificationCenter.current()
    var pendingRequests: [UNNotificationRequest] = [] // notificaitons on stack
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    /// for delegate. required to show notification even while the app is active.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await getPengingRequests() // update request pendding list
        return [.sound, .banner]
    }
    
    /// notification authorization request
    func askNotificationPermission() async -> Bool{
        let task = Task {
            return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        }
        let result = await task.result
        switch result {
        case .success(let allowed):
            return allowed
        case .failure (let error):
            print("Permission denied: \(error.localizedDescription)")
            return false
        }
    }
    
    /// obtain authorization status (notDetermind, authorized, denied)
    func getNotifucationStatus() async -> UNAuthorizationStatus{
        let setting = await notificationCenter.notificationSettings()
        return setting.authorizationStatus
    }
    
    /// add scheduled notification
    func scheduleNotification(_ seconds: Double) async{
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.body = "It looks hangry"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        let task = Task {
            try await notificationCenter.add(request)
        }
        let result = await task.result
        if case .success = result {
            print("Notification scheduled")
            await getPengingRequests() // update request pendding list
        }
    }
    
    /// add scheduled notification
    func scheduleNotification(_ date: DateComponents) async{
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.body = "It looks hangry"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        let task = Task {
            try await notificationCenter.add(request)
        }
        let result = await task.result
        if case .success = result {
            print("Notification scheduled")
            await getPengingRequests() // update request pendding list
        }
    }
    
    /// update pending notificaion list
    func getPengingRequests() async {
        pendingRequests = await notificationCenter.pendingNotificationRequests()
        print("Pending requests: \(pendingRequests.count)")
    }
    
    /// cancel specified notification
    func removeRequest(identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        await getPengingRequests()  // update request pendding list
    }
    
    /// cancel all notification
    func clearAllRequests() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await getPengingRequests()  // update request pendding list
    }
}
