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
                        Button("Schedule Notification") {
                            Task {
                                await notificationManager.scheduleNotification()
                            }
                        }
                        .buttonStyle(.borderedProminent)
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
            .padding(.top, 200)
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
