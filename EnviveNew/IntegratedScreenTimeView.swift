import SwiftUI
import FamilyControls

struct IntegratedScreenTimeView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @State private var userType: UserType = .child // This would come from your user authentication
    @State private var selectedTab: ScreenTimeTab = .child

    enum UserType {
        case parent, child
    }

    enum ScreenTimeTab: String, CaseIterable {
        case child = "Child View"
        case parent = "Parent Controls"

        var icon: String {
            switch self {
            case .child: return "person.circle"
            case .parent: return "person.2.badge.gearshape"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                authorizationSection

                if screenTimeManager.isAuthorized {
                    tabSelectorSection
                    contentSection
                }
            }
            .navigationTitle("Screen Time Management")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var authorizationSection: some View {
        Group {
            switch screenTimeManager.authorizationStatus {
            case .notDetermined:
                VStack(spacing: 16) {
                    Image(systemName: "hourglass.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Enable Screen Time Controls")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Grant permission to manage screen time and app usage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Enable Screen Time") {
                        Task {
                            try? await screenTimeManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()

            case .denied:
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Screen Time Access Denied")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    Text("Please enable Screen Time access in Settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

            case .approved:
                EmptyView()

            @unknown default:
                EmptyView()
            }
        }
    }

    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(ScreenTimeTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))

                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.blue : Color.clear)
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                }
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var contentSection: some View {
        ScrollView {
            switch selectedTab {
            case .child:
                ChildScreenTimeView()
                    .padding()

            case .parent:
                ParentControlView()
                    .padding()
            }
        }
    }
}

// MARK: - Implementation Details & Architecture

/*
## Screen Time Implementation Architecture

### 1. **Parent Role Workflow**
```
Parent opens app → ParentControlView
├── Select child from relationship list
├── Choose apps to restrict using FamilyActivityPicker
├── Set daily time limits (slider: 15min - 5hours)
├── Apply settings → Stored in Supabase + Local UserDefaults
└── Settings synced to child's device
```

### 2. **Child Role Workflow**
```
Child opens app → ChildScreenTimeView
├── Load parent-set restrictions from Supabase
├── Display earned minutes from task completion
├── Choose session duration (15, 30, 60 min buttons)
├── Start session → Apps unblocked temporarily
└── Session ends → Apps re-blocked automatically
```

### 3. **Core Implementation Components**

**DeviceActivity Framework:**
- `ActivityScheduler.swift` - Schedules monitoring periods
- `EnviveNewDeviceActivityMonitor.swift` - Handles app blocking/unblocking
- App Group: `group.com.envivenew.screentime` for data sharing

**Settings Management:**
- `SettingsManager.swift` - Applies ManagedSettings restrictions
- `AppSelectionStore.swift` - Stores FamilyActivitySelection
- `ScreenTimeRewardManager.swift` - XP to minutes conversion

**Data Models:**
- `ChildScreenTimeSettings` - Parent-defined restrictions per child
- User relationship system via Supabase (parent_user_id → child_user_id)

### 4. **Technical Flow**

**Parent Sets Limits:**
1. Parent selects child from `user_relationship` table
2. Uses `FamilyActivityPicker` to select restricted apps
3. Settings stored in Supabase: `child_screen_time_settings` table
4. Local cache in UserDefaults for immediate access

**Child Requests Session:**
1. Child views earned minutes from `task_completion` XP system
2. Selects session duration (limited by earned time)
3. `ManagedSettingsStore.clearAllSettings()` removes restrictions
4. `DeviceActivityCenter.startMonitoring()` schedules re-blocking
5. When timer expires, restrictions automatically reapply

**Session Management:**
- Session starts: Apps unblocked, timer started
- Session active: Progress bar shows remaining time
- Session ends: Apps re-blocked, earned minutes decremented
- Early end: Manual stop button available

### 5. **Key Features**

**Parent Dashboard:**
- Child selection grid with relationship status
- App restriction picker with visual feedback
- Time limit slider (15min - 5hour range)
- Apply settings with loading state

**Child Interface:**
- Earned time display (from XP → minutes conversion)
- Session duration selection (15/30/60 min buttons)
- Active session progress tracking
- Current restrictions overview

**Real-time Sync:**
- Parent settings immediately sync to child device
- Task completion automatically updates earned minutes
- Session changes reflected across all interfaces

### 6. **Required Setup**

**Xcode Configuration:**
- Family Controls entitlement: `com.apple.developer.family-controls`
- DeviceActivity Monitor Extension target
- App Group capability for data sharing
- Physical device testing (Simulator not supported)

**Database Schema:**
```sql
-- Parent-child relationships (already implemented)
user_relationship: parent_user_id, child_user_id, status

-- Screen time settings (needs implementation)
child_screen_time_settings:
  - child_user_id
  - daily_limit_minutes
  - restricted_app_tokens (JSON)
  - created_by_parent_id
  - created_at, updated_at
```

This architecture enables seamless parent-child screen time management with task-based earning system integration.
*/

#Preview {
    IntegratedScreenTimeView()
}