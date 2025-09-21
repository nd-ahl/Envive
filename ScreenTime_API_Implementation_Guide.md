# Screen Time API Implementation Guide for EnviveNew

## Overview

This guide provides comprehensive implementation steps for integrating Apple's Screen Time APIs into the EnviveNew app. The Screen Time API consists of three interconnected frameworks that work together to provide comprehensive device activity monitoring and management.

## Framework Architecture

### 1. FamilyControls Framework
- **Purpose**: Authorization gateway and app/category selection
- **Key Components**: AuthorizationCenter, FamilyActivityPicker
- **Role**: Requests permission from users and provides UI for selecting apps/categories to manage

### 2. ManagedSettings Framework
- **Purpose**: Enforcement engine for restrictions
- **Key Components**: ManagedSettingsStore, ShieldSettings
- **Role**: Applies actual restrictions like app blocking, time limits, and content filtering

### 3. DeviceActivity Framework
- **Purpose**: Scheduling and monitoring system
- **Key Components**: DeviceActivityMonitor, DeviceActivityCenter, DeviceActivitySchedule
- **Role**: Determines when restrictions are active and monitors usage events

## Prerequisites

### 1. Apple Developer Requirements
- **Entitlement Required**: `com.apple.developer.family-controls`
- **Application Process**: Must request special permission from Apple with clear use case explanation
- **Distribution**: Required for TestFlight and App Store distribution

### 2. Technical Requirements
- **iOS Version**: iOS 15.0+ (iOS 16.0+ for advanced features)
- **Testing**: Physical device required (Simulator not supported)
- **Architecture**: App Group required for data sharing between main app and extensions

### 3. Project Setup
```swift
// Add to Signing & Capabilities in Xcode
// Family Controls capability
```

## Implementation Steps

### Step 1: Project Configuration

#### 1.1 Add Entitlements
1. Open Xcode project
2. Select main app target
3. Go to Signing & Capabilities
4. Add "Family Controls" capability
5. Verify entitlement appears in entitlements file

#### 1.2 Create App Group
1. Add "App Groups" capability to main app
2. Create new app group: `group.com.yourcompany.envivenew.screentime`
3. Enable same app group for DeviceActivity extension

#### 1.3 Add Framework Imports
```swift
import FamilyControls
import ManagedSettings
import DeviceActivity
```

### Step 2: Authorization Implementation

#### 2.1 Basic Authorization Setup
```swift
import SwiftUI
import FamilyControls

@main
struct EnviveNewApp: App {
    let authorizationCenter = AuthorizationCenter.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
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
```

#### 2.2 Authorization Status Monitoring
```swift
class ScreenTimeManager: ObservableObject {
    private let authorizationCenter = AuthorizationCenter.shared
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    init() {
        updateAuthorizationStatus()
    }

    func updateAuthorizationStatus() {
        authorizationStatus = authorizationCenter.authorizationStatus
    }

    func requestAuthorization() async throws {
        try await authorizationCenter.requestAuthorization(for: .individual)
        updateAuthorizationStatus()
    }

    func revokeAuthorization() {
        authorizationCenter.revokeAuthorization { [weak self] result in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
            }
        }
    }
}
```

### Step 3: App Selection Interface

#### 3.1 Family Activity Picker Implementation
```swift
import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @State private var familyActivitySelection = FamilyActivitySelection()
    @Binding var selectedApps: FamilyActivitySelection
    @State private var isPresentingPicker = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Select Apps to Manage") {
                isPresentingPicker = true
            }
            .familyActivityPicker(
                isPresented: $isPresentingPicker,
                selection: $familyActivitySelection
            )
            .onChange(of: familyActivitySelection) { selection in
                selectedApps = selection
            }

            if !familyActivitySelection.applicationTokens.isEmpty {
                Text("Selected \(familyActivitySelection.applicationTokens.count) apps")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

#### 3.2 Selection Storage Model
```swift
import Foundation
import FamilyControls

class AppSelectionStore: ObservableObject {
    @Published var familyActivitySelection = FamilyActivitySelection()

    private let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.envivenew.screentime")
    private let selectionKey = "familyActivitySelection"

    init() {
        loadSelection()
    }

    func saveSelection() {
        if let encoded = try? JSONEncoder().encode(familyActivitySelection) {
            userDefaults?.set(encoded, forKey: selectionKey)
        }
    }

    func loadSelection() {
        guard let data = userDefaults?.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        familyActivitySelection = selection
    }
}
```

### Step 4: DeviceActivity Monitor Extension

#### 4.1 Create Monitor Extension
1. File → New → Target
2. Choose "Device Activity Monitor Extension"
3. Name: "EnviveNewMonitor"
4. Add to same app group

#### 4.2 Monitor Implementation
```swift
import DeviceActivity
import ManagedSettings
import Foundation

class EnviveNewDeviceActivityMonitor: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.envivenew.screentime")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load app selection from shared storage
        guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }

        // Apply restrictions
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        // Log activity start
        logActivity("Restrictions applied for activity: \(activity)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Remove all restrictions
        store.clearAllSettings()

        // Log activity end
        logActivity("Restrictions removed for activity: \(activity)")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Handle threshold events (time limits reached)
        guard let data = userDefaults?.data(forKey: "familyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }

        // Apply additional restrictions when threshold reached
        store.shield.applications = selection.applicationTokens

        logActivity("Time threshold reached for event: \(event), activity: \(activity)")
    }

    private func logActivity(_ message: String) {
        // Log to shared user defaults for main app to read
        let timestamp = Date().timeIntervalSince1970
        let logEntry = "\(timestamp): \(message)"

        var logs = userDefaults?.stringArray(forKey: "activityLogs") ?? []
        logs.append(logEntry)

        // Keep only last 100 entries
        if logs.count > 100 {
            logs = Array(logs.suffix(100))
        }

        userDefaults?.set(logs, forKey: "activityLogs")
    }
}
```

### Step 5: Scheduling and Activity Management

#### 5.1 Activity Scheduler
```swift
import DeviceActivity
import Foundation

class ActivityScheduler: ObservableObject {
    private let center = DeviceActivityCenter()
    @Published var isMonitoring = false

    // MARK: - Schedule Management

    func startTimerBasedRestrictions(durationMinutes: Int) {
        let activityName = DeviceActivityName("timerRestriction")

        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(
                hour: Calendar.current.component(.hour, from: startTime),
                minute: Calendar.current.component(.minute, from: startTime)
            ),
            intervalEnd: DateComponents(
                hour: Calendar.current.component(.hour, from: endTime),
                minute: Calendar.current.component(.minute, from: endTime)
            ),
            repeats: false
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
            isMonitoring = true
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    func startDailySchedule(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        let activityName = DeviceActivityName("dailyRestriction")

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMinute),
            intervalEnd: DateComponents(hour: endHour, minute: endMinute),
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
            isMonitoring = true
        } catch {
            print("Failed to start daily monitoring: \(error)")
        }
    }

    func stopAllMonitoring() {
        center.stopMonitoring()
        isMonitoring = false
    }

    // MARK: - Event-based Monitoring

    func startUsageThresholdMonitoring(thresholdMinutes: Int, for selection: FamilyActivitySelection) {
        let activityName = DeviceActivityName("usageThreshold")
        let eventName = DeviceActivityEvent.Name("thresholdReached")

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: thresholdMinutes)
        )

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            isMonitoring = true
        } catch {
            print("Failed to start threshold monitoring: \(error)")
        }
    }
}
```

### Step 6: Managed Settings Implementation

#### 6.1 Settings Manager
```swift
import ManagedSettings
import FamilyControls

class SettingsManager: ObservableObject {
    private let store = ManagedSettingsStore()

    // MARK: - App Restrictions

    func blockApps(_ selection: FamilyActivitySelection) {
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }

        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        }
    }

    func unblockApps() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    func clearAllSettings() {
        store.clearAllSettings()
    }

    // MARK: - Advanced Settings (iOS 16+)

    @available(iOS 16.0, *)
    func configureAdvancedRestrictions() {
        // Prevent app installation/deletion
        store.application.denyAppInstallation = true
        store.application.denyAppRemoval = true

        // Account settings restrictions
        store.account.lockAccounts = true

        // Media restrictions
        store.media.denyExplicitContent = true
        store.media.maximumMovieRating = 1000 // PG-13

        // Cellular restrictions
        store.cellular.lockCellularPlan = true

        // Game Center restrictions
        store.gameCenter.denyMultiplayerGaming = true
        store.gameCenter.denyAddingFriends = true
    }
}
```

### Step 7: Integration with EnviveNew's XP System

#### 7.1 XP-Based Screen Time Rewards
```swift
class ScreenTimeRewardManager: ObservableObject {
    private let settingsManager = SettingsManager()
    private let scheduler = ActivityScheduler()
    @Published var earnedMinutes: Int = 0
    @Published var isScreenTimeActive = false

    private let xpToMinutesRatio: Double = 10.0 // 10 XP = 1 minute

    func redeemXPForScreenTime(xpAmount: Int) -> Int {
        let earnedMinutes = Int(Double(xpAmount) / xpToMinutesRatio)
        self.earnedMinutes += earnedMinutes
        return earnedMinutes
    }

    func startScreenTimeSession(durationMinutes: Int) {
        guard durationMinutes <= earnedMinutes else {
            print("Insufficient earned minutes")
            return
        }

        // Remove used minutes
        earnedMinutes -= durationMinutes

        // Temporarily lift restrictions for earned time
        settingsManager.unblockApps()
        isScreenTimeActive = true

        // Schedule re-application of restrictions
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(durationMinutes * 60)) {
            self.endScreenTimeSession()
        }
    }

    private func endScreenTimeSession() {
        // Re-apply restrictions
        // Note: Would need to store selected apps to reapply
        isScreenTimeActive = false
    }
}
```

### Step 8: UI Integration

#### 8.1 Screen Time Management View
```swift
import SwiftUI
import FamilyControls

struct ScreenTimeManagementView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var appSelectionStore = AppSelectionStore()
    @StateObject private var scheduler = ActivityScheduler()
    @StateObject private var rewardManager = ScreenTimeRewardManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                authorizationSection
                appSelectionSection
                rewardSection
                controlsSection
            }
            .padding()
            .navigationTitle("Screen Time")
        }
    }

    private var authorizationSection: some View {
        Group {
            switch screenTimeManager.authorizationStatus {
            case .notDetermined:
                Button("Enable Screen Time Controls") {
                    Task {
                        try? await screenTimeManager.requestAuthorization()
                    }
                }
                .buttonStyle(.borderedProminent)

            case .denied:
                VStack {
                    Text("Screen Time Access Denied")
                        .foregroundColor(.red)
                    Text("Please enable in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            case .approved:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Screen Time Authorized")
                }

            @unknown default:
                EmptyView()
            }
        }
    }

    private var appSelectionSection: some View {
        VStack(alignment: .leading) {
            Text("Managed Apps")
                .font(.headline)

            AppSelectionView(selectedApps: $appSelectionStore.familyActivitySelection)
                .onChange(of: appSelectionStore.familyActivitySelection) { _ in
                    appSelectionStore.saveSelection()
                }
        }
    }

    private var rewardSection: some View {
        VStack(alignment: .leading) {
            Text("Earned Screen Time")
                .font(.headline)

            HStack {
                Text("Available Minutes: \(rewardManager.earnedMinutes)")
                Spacer()
                if rewardManager.isScreenTimeActive {
                    Text("Session Active")
                        .foregroundColor(.green)
                }
            }

            Button("Redeem 100 XP for 10 minutes") {
                // This would integrate with your existing XP system
                let minutes = rewardManager.redeemXPForScreenTime(xpAmount: 100)
                print("Earned \(minutes) minutes")
            }
            .disabled(rewardManager.isScreenTimeActive)
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 15) {
            Text("Quick Controls")
                .font(.headline)

            Button("Start 30-minute Study Session") {
                scheduler.startTimerBasedRestrictions(durationMinutes: 30)
            }
            .buttonStyle(.borderedProminent)
            .disabled(scheduler.isMonitoring)

            Button("Stop All Restrictions") {
                scheduler.stopAllMonitoring()
            }
            .buttonStyle(.bordered)
            .disabled(!scheduler.isMonitoring)
        }
    }
}
```

### Step 9: Data Models and Persistence

#### 9.1 Core Data Integration
```swift
import CoreData
import Foundation

// Add to your existing Core Data model
extension TaskItem {
    var screenTimeReward: Int32 {
        get { screenTimeRewardMinutes }
        set { screenTimeRewardMinutes = newValue }
    }
}

// Screen Time Activity Model
@objc(ScreenTimeActivity)
public class ScreenTimeActivity: NSManagedObject {
    @NSManaged public var activityName: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var earnedMinutes: Int32
    @NSManaged public var usedMinutes: Int32
    @NSManaged public var isActive: Bool
}

extension ScreenTimeActivity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScreenTimeActivity> {
        return NSFetchRequest<ScreenTimeActivity>(entityName: "ScreenTimeActivity")
    }
}
```

### Step 10: Testing and Debugging

#### 10.1 Testing Checklist
- [ ] Physical device testing (Simulator not supported)
- [ ] Authorization flow testing
- [ ] App selection and persistence
- [ ] DeviceActivity monitor extension functionality
- [ ] Schedule creation and monitoring
- [ ] Restriction application and removal
- [ ] XP redemption integration
- [ ] Background activity monitoring

#### 10.2 Debugging Tips
```swift
// Add to monitor extension for debugging
private func debugLog(_ message: String) {
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let logMessage = "[\(timestamp)] \(message)"

    // Store in UserDefaults for main app to read
    let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.envivenew.screentime")
    var logs = userDefaults?.stringArray(forKey: "debugLogs") ?? []
    logs.append(logMessage)

    // Keep only recent logs
    if logs.count > 50 {
        logs = Array(logs.suffix(50))
    }

    userDefaults?.set(logs, forKey: "debugLogs")
}
```

## Known Limitations and Considerations

### 1. Platform Limitations
- **Simulator**: Screen Time APIs don't work in iOS Simulator
- **Testing**: Requires physical device for all testing
- **Distribution**: Requires special entitlement for App Store

### 2. Extension Limitations
- **Debugging**: Cannot use print() or traditional debugging in extensions
- **Network**: Limited network access in monitor extensions
- **UI**: No UI updates possible from monitor extensions
- **Data Sharing**: Must use App Groups for data sharing

### 3. Privacy Considerations
- **User Consent**: Always clearly explain what data is accessed
- **Data Minimization**: Only request access to necessary apps/categories
- **Transparency**: Provide clear controls for users to manage permissions

### 4. Performance Considerations
- **Battery**: Location and continuous monitoring can impact battery
- **Storage**: Activity logs and data can accumulate over time
- **Memory**: Be mindful of memory usage in extensions

## Migration Strategy from Current Implementation

### Phase 1: Parallel Implementation
1. Keep existing FamilyControls integration
2. Add new Screen Time API alongside
3. Test thoroughly with subset of users

### Phase 2: Feature Enhancement
1. Add advanced scheduling capabilities
2. Implement usage threshold monitoring
3. Enhance XP reward system integration

### Phase 3: Full Migration
1. Deprecate old implementation
2. Migrate user data and preferences
3. Update UI to use new capabilities

## Support and Resources

### Apple Documentation
- [Screen Time API Documentation](https://developer.apple.com/documentation/screentime)
- [WWDC 2021: Meet the Screen Time API](https://developer.apple.com/videos/play/wwdc2021/10123/)
- [WWDC 2022: What's new in Screen Time API](https://developer.apple.com/videos/play/wwdc2022/110336/)

### Community Resources
- Apple Developer Forums - Device Activity section
- Stack Overflow - screen-time-api tag
- GitHub examples and open source implementations

This implementation guide provides a comprehensive foundation for integrating Apple's Screen Time APIs into EnviveNew while maintaining compatibility with the existing gamification and XP system.