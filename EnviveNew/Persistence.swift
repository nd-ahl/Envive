//
//  Persistence.swift
//  EnviveNew
//
//  Created by Paul Ahlstrom on 9/20/25.
//

import CoreData
import Combine

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        print("💾 PersistenceController init() started (inMemory: \(inMemory))")
        container = NSPersistentContainer(name: "EnviveNew")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        print("💾 Loading persistent stores...")
        let startTime = Date()
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            let duration = Date().timeIntervalSince(startTime)
            print("💾 Persistent store loaded in \(String(format: "%.2f", duration)) seconds")
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                print("❌ FATAL: Core Data failed to load: \(error)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        print("✅ PersistenceController init() completed")
    }

    // MARK: - Async Loading

    /// Load Core Data asynchronously off the main thread for faster app startup
    static func loadAsync() async -> PersistenceController {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let controller = PersistenceController.shared
                continuation.resume(returning: controller)
            }
        }
    }
}
