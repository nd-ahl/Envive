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
                .task {
                    await requestScreenTimeAuthorization()
                }
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
