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
        // Handle the URL scheme - app is already opening so just log for now
        // You can add specific handling here if needed for different URL paths
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
