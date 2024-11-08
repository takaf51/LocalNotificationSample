//
//  ContentView.swift
//  LocalNotificationSample
//
//  Created by Taka on 2024-11-08.
//

import SwiftUI

struct ContentView: View {
    
    enum NotificationPermissionStatus {
        case notDetermined, authorized, denied
    }
    
    @State private var permissionSatatus: NotificationPermissionStatus = .notDetermined
    @State private var datetime: Date = .now
    @State private var interval: Int = 10
    @Environment(\.scenePhase) var scenePhase
    var notificationManager: NotificationManager
    
    init() {
        let manager = NotificationManager()
        self.notificationManager = manager
    }

    var body: some View {
        NavigationStack {
            VStack(spacing:30) {
                switch permissionSatatus {
                    case .notDetermined:
                        Button("Request Permission") {
                            Task {
                                let result = await notificationManager.askNotificationPermission()
                                permissionSatatus = result ? .authorized : .denied
                            }
                        }
                        .buttonStyle(.bordered)
                    case .denied:
                        Button("Open Settings") {
                            Task {
                                await openSettings()
                            }
                        }
                        .buttonStyle(.bordered)
                    case .authorized:
                    VStack(spacing: 50) {
                        GroupBox("Interval Notification") {
                            Stepper("Interval \(interval) sec later", value: $interval, in: 1...30)
                            Button("Schedule Notification") {
                                Task {
                                    await notificationManager.scheduleNotification(Double(interval))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        GroupBox("Calender Notification") {
                            DatePicker("Select Date", selection: $datetime)
                            Button("Schedule Notification") {
                                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: datetime)
                                Task {
                                    await notificationManager.scheduleNotification(dateComponents)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal, 20)

                }
                List{
                    ForEach(notificationManager.pendingRequests, id: \.identifier) { request in
                        HStack {
                            Text(request.content.title)
                            Spacer()
                            Text(request.identifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button("Delete", systemImage: "minus.circle", role: .destructive) {
                                Task {
                                    await notificationManager.removeRequest(identifier: request.identifier)
                                }
                                
                            }
                        }
                    }
                }
                
            }
            .padding(.top, 150)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        let status = await notificationManager.getNotifucationStatus()
                        switch status {
                        case .notDetermined:
                            permissionSatatus = .notDetermined
                        case .authorized:
                            permissionSatatus = .authorized
                        case .denied:
                            permissionSatatus = .denied
                        default:
                            break
                        }
                        
                        await notificationManager.getPengingRequests()   // update request pendding list
                    }
                }
            }
            .navigationTitle("Notification")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button{
                        Task {
                            await notificationManager.clearAllRequests()
                        }
                        
                    } label: {
                        Image(systemName: "clear.fill")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
    
    /// open privacy setting to set notification on
    func openSettings() async{
        guard
            let settingsURL = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsURL)
        else { return }
        
        await UIApplication.shared.open(settingsURL)
    }
}

#Preview {
    ContentView()
}
