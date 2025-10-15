# Device Mode Architecture

## Overview

This document describes the parent/child mode switching architecture built for single-device testing that is fully prepared for Firebase migration.

## Architecture Summary

### Clean Separation of Concerns

```
User Interaction
       ↓
RootNavigationView (Router)
       ↓
DeviceModeManager (Protocol)
       ↓
LocalDeviceModeManager (Implementation)
       ↓
StorageService (Protocol)
       ↓
UserDefaultsStorage (Implementation)
```

### Key Components

1. **DeviceMode.swift** - Core domain models
   - `DeviceMode` enum (parent/child)
   - `UserProfile` struct (user identity with mode)
   - Location: `/EnviveNew/Services/DeviceMode/DeviceMode.swift`

2. **DeviceModeManager.swift** - Business logic
   - `DeviceModeManager` protocol (interface)
   - `LocalDeviceModeManager` (local implementation)
   - Future: `FirebaseDeviceModeManager` (commented template)
   - Location: `/EnviveNew/Services/DeviceMode/DeviceModeManager.swift`

3. **RootNavigationView.swift** - Main routing coordinator
   - Observes `DeviceModeManager`
   - Routes to Parent or Child tab views
   - Shows floating mode switcher for testing
   - Location: `/EnviveNew/Views/Shared/RootNavigationView.swift`

4. **ModeSwitcherView.swift** - UI for mode switching
   - Modal interface to switch modes
   - `ModeSwitcherButton` - Floating action button
   - Location: `/EnviveNew/Views/Shared/ModeSwitcherView.swift`

5. **ChildDashboardView.swift** - Child interface
   - Shows assigned tasks
   - Displays XP balance and credibility
   - Location: `/EnviveNew/Views/Child/ChildDashboardView.swift`

6. **DependencyContainer.swift** - Dependency injection
   - Single point to swap implementations
   - Line 78-80: `deviceModeManager` injection
   - Location: `/EnviveNew/Core/DependencyContainer.swift`

## How Mode Switching Works

### Current Flow (Local Storage)

1. User taps floating mode switcher button (top-right)
2. `ModeSwitcherView` presents modal
3. User selects Parent or Child mode
4. `LocalDeviceModeManager.switchMode()` called
5. Mode saved to `StorageService` (UserDefaults)
6. `@Published` property triggers `RootNavigationView` update
7. SwiftUI animates transition to new tab view

### Future Flow (Firebase)

Same UI flow, but:
- `FirebaseDeviceModeManager` replaces `LocalDeviceModeManager`
- Mode synced to Firestore user document
- Real-time listeners update on remote changes
- Each physical device has persistent mode
- Family relationships tracked in Firebase

## Migration Path to Firebase

### Step 1: Create Firebase Implementation

```swift
class FirebaseDeviceModeManager: DeviceModeManager {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    // Implement protocol methods...
}
```

### Step 2: Update DependencyContainer (ONE LINE CHANGE)

```swift
// In DependencyContainer.swift:78-80
lazy var deviceModeManager: DeviceModeManager = {
    FirebaseDeviceModeManager(auth: firebaseAuth, db: firestore)  // ← Change this
}()
```

### Step 3: No Changes Needed To:
- ✅ RootNavigationView
- ✅ ModeSwitcherView
- ✅ ChildDashboardView
- ✅ ParentDashboardView
- ✅ Any other UI code

## Testing the Feature

### How to Test Now

1. Build and run the app
2. Look for floating button in top-right (shows current mode)
3. Tap button to open mode switcher
4. Select "Parent" mode → See parent dashboard with task assignment
5. Select "Child" mode → See child dashboard with task list
6. Assign task in Parent mode → Switch to Child mode → See assigned task

### What You Can Test

✅ Task assignment flow (parent → child)
✅ Task completion flow (child → parent)
✅ Task approval/denial (parent)
✅ XP awarding and credibility changes
✅ Screen Time earning workflow

### What You CANNOT Test Yet

❌ Real multi-device sync (requires Firebase)
❌ Screen Time API (requires physical devices)
❌ Push notifications across devices

## Code Quality

### Follows SOLID Principles

- **Single Responsibility**: Each class has one job
- **Open/Closed**: Open for extension (Firebase), closed for modification
- **Liskov Substitution**: Any DeviceModeManager implementation works
- **Interface Segregation**: Minimal protocol surface
- **Dependency Inversion**: Depends on protocols, not concrete classes

### Architecture Benefits

1. **Testable**: Mock DeviceModeManager for unit tests
2. **Flexible**: Swap implementations without changing UI
3. **Type-Safe**: Protocol-driven design catches errors at compile time
4. **Observable**: Combine publishers for reactive UI updates
5. **Future-Proof**: Firebase migration is a single-line change

## Entry Point

- **App Launch**: `EnviveNewApp.swift:23` → `RootNavigationView()`
- **Dependency Injection**: `DependencyContainer.shared.deviceModeManager`

## Files Created

1. `/EnviveNew/Services/DeviceMode/DeviceMode.swift` (53 lines)
2. `/EnviveNew/Services/DeviceMode/DeviceModeManager.swift` (110 lines)
3. `/EnviveNew/Views/Shared/RootNavigationView.swift` (162 lines)
4. `/EnviveNew/Views/Shared/ModeSwitcherView.swift` (289 lines)
5. `/EnviveNew/Views/Child/ChildDashboardView.swift` (408 lines)

## Files Modified

1. `/EnviveNew/Core/DependencyContainer.swift` (added deviceModeManager)
2. `/EnviveNew/EnviveNewApp.swift` (changed ContentView → RootNavigationView)

## Next Steps

### Immediate Testing (This Week)
- Test task assignment → completion → approval workflow
- Verify XP calculations work correctly
- Test credibility changes affect rewards
- Create demo scenarios for user feedback

### Physical Device Testing (When Ready)
- Deploy to 2 devices via TestFlight
- Test Screen Time API functionality
- Validate app blocking/unblocking

### Firebase Migration (Future)
1. Add Firebase SDK to project
2. Create Firestore data structure for families
3. Implement `FirebaseDeviceModeManager`
4. Change 1 line in DependencyContainer.swift
5. Deploy and test multi-device sync

---

**Architecture Status**: ✅ Complete and production-ready for local testing
**Firebase Ready**: ✅ Yes - protocol-based design allows seamless migration
**Build Status**: ✅ Compiles successfully (Xcode)
