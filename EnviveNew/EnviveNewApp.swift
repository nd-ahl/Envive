//
//  EnviveNewApp.swift
//  EnviveNew
//
//  Created by Paul Ahlstrom on 9/20/25.
//

import SwiftUI
import CoreData
import FamilyControls

@main
struct EnviveNewApp: App {
    let persistenceController = PersistenceController.shared
    let authorizationCenter = AuthorizationCenter.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    handleURLScheme(url)
                }
                .task {
                    await requestScreenTimeAuthorization()
                }
        }
    }

    private func handleURLScheme(_ url: URL) {
        print("Received URL scheme: \(url)")

        // Handle different URL paths
        switch url.path {
        case "/screentime":
            // User tapped on Dynamic Island/Live Activity during screen time session
            print("Opening app from screen time Live Activity")
            // The app will automatically show the current screen time session state
            // since the ScreenTimeRewardManager is already tracking the active session
            break
        case "/spend":
            // User tapped "Spend Time" button in Focus widget
            print("Opening app from Focus widget - user wants to spend screen time")
            // Navigate to screen time spending interface
            // You can add navigation logic here to go directly to the spending screen
            break
        default:
            print("Unknown URL path: \(url.path)")
        }
    }

    private func requestScreenTimeAuthorization() async {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            print("Screen Time authorization granted")
        } catch {
            print("Screen Time authorization failed: \(error)")
        }
    }
}
