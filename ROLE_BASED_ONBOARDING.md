# Role-Based Onboarding Implementation

## Overview
This document describes the implementation of role-based onboarding with proper household access controls for the Envive app.

## Implementation Summary

### New Components

#### 1. HouseholdService - New Method
**File**: `EnviveNew/Services/Household/HouseholdService.swift`

Added `getAllProfilesByInviteCode()` method that retrieves ALL profiles (both parent and child) from a household using an invite code.

```swift
func getAllProfilesByInviteCode(_ inviteCode: String) async throws -> [Profile]
```

#### 2. ParentProfileSelectorView
**File**: `EnviveNew/Views/Onboarding/ParentProfileSelectorView.swift`

New view for parent onboarding that displays ALL household profiles (parent and child):
- Shows profiles organized into "Parents" and "Children" sections
- Parents CAN select any role (including child roles for troubleshooting)
- Displays role badges to clearly identify parent vs child profiles
- Updates button text to show "Continue as [Name]"

#### 3. ParentOnboardingCoordinator
**File**: `EnviveNew/Views/Onboarding/ParentOnboardingCoordinator.swift`

Manages the parent onboarding flow when joining an existing household:
1. Enter household invite code
2. Select profile (any role - parent or child)
3. Link device to selected profile
4. Set appropriate device mode based on selected role

#### 4. Updated ChildProfileSelectorView
**File**: `EnviveNew/Views/Onboarding/ChildProfileSelectorView.swift`

Enhanced child onboarding profile selector:
- Now displays ALL profiles (parent and child)
- Parent profiles are visible but DISABLED/UNSELECTABLE
- Shows lock icon on parent profiles
- Organizes profiles into sections:
  - "Parent" section (disabled, informational only)
  - "Siblings" section (selectable)
- Helps children see their parent's name while selecting their own profile

#### 5. Updated EnviveNewApp.swift
**File**: `EnviveNew/EnviveNewApp.swift`

Updated onboarding flow to handle both parent and child joining flows:
- If creating household → SignInView (parent only)
- If joining household + parent role → ParentOnboardingCoordinator
- If joining household + child role → ChildOnboardingCoordinator

## Onboarding Flows

### Parent Onboarding Flow (Joining Existing Household)

1. **User Selection**: User selects "Parent" during onboarding
2. **Household Selection**: User chooses "Join Household"
3. **Enter Code**: User enters household invite code (e.g., 834228)
4. **Profile Selection**: ParentProfileSelectorView displays ALL profiles:
   - Parent roles (e.g., Walter White)
   - Child roles (e.g., Jesse Pinkman)
   - All profiles are SELECTABLE
5. **Profile Selected**: Parent selects their profile (e.g., Walter White)
6. **Device Linked**:
   - Device is linked to selected profile
   - Device mode set to PARENT or CHILD based on selection
   - Household context is set
7. **Navigation**: App navigates to appropriate dashboard (parent or child)

### Child Onboarding Flow

1. **User Selection**: User selects "Child" during onboarding
2. **Household Selection**: User chooses "Join Household"
3. **Enter Code**: User enters household invite code (e.g., 834228)
4. **Profile Selection**: ChildProfileSelectorView displays:
   - Parent profiles (visible but DISABLED with lock icon)
   - Sibling profiles (selectable)
5. **Profile Selected**: Child selects their profile (e.g., Jesse Pinkman)
6. **Device Linked**:
   - Device is linked to selected child profile
   - Device mode set to CHILD
   - Household context is set
7. **Navigation**: App navigates to child dashboard

## Access Controls

### Parent Access Controls
- ✅ Can see ALL profiles in household
- ✅ Can select any role (parent or child)
- ✅ Dashboard shows only their household's children
- ✅ Can approve tasks from their household's children
- ✅ Can switch between roles for troubleshooting

### Child Access Controls
- ✅ Can see parent profiles (but cannot select them)
- ✅ Can select only child profiles
- ✅ Parent names are visible for context
- ✅ Dashboard shows only their own tasks
- ✅ Can view parent's name in UI

## Data Isolation

### Household Context
When a profile is selected during onboarding:
1. Profile data is loaded from Supabase
2. `HouseholdContext.setHouseholdContext()` is called automatically on login
3. Household ID and parent ID are persisted
4. All data queries are scoped to household

### Task Flow Example (Household 834228)
1. Jesse Pinkman (child) uploads/completes a task
2. Task stored with:
   - Jesse's user ID
   - Household ID: 834228
   - Task details
3. Walter White (parent) logs in
4. HouseholdContext loads household 834228 children (Jesse)
5. TaskService filters tasks to household 834228 only
6. Walter sees Jesse's task in dashboard
7. Walter can approve/decline the task

## Testing Plan

### Test 1: Parent Onboarding (Joining Household)
**Scenario**: Parent joining existing household 834228

**Steps**:
1. Reset onboarding (Settings > Debug & Testing > Reset Onboarding)
2. Start onboarding flow
3. Select "Parent" as user role
4. Select "Join Household"
5. Enter household code: 834228
6. **Verify**: Role selection screen shows:
   - ✅ Walter White (parent) with "Parent account" label
   - ✅ Jesse Pinkman (child) with age label
   - ✅ Both profiles are selectable
7. Select Walter White (parent role)
8. **Verify**: App navigates to parent dashboard
9. **Verify**: Children overview shows ONLY Jesse Pinkman
10. **Verify**: No legacy test profiles (Sarah, Jake) visible

### Test 2: Parent Troubleshooting (Selecting Child Profile)
**Scenario**: Parent needs to troubleshoot child device

**Steps**:
1. Reset onboarding
2. Start onboarding as parent
3. Join household 834228
4. On profile selection screen, select Jesse Pinkman (child)
5. **Verify**: App navigates to CHILD dashboard
6. **Verify**: Device functions as child (Jesse's view)
7. **Verify**: Can see parent name (Walter White) in UI

### Test 3: Child Onboarding (Joining Household)
**Scenario**: Child joining existing household 834228

**Steps**:
1. Reset onboarding
2. Start onboarding flow
3. Select "Child" as user role
4. Select "Join Household"
5. Enter household code: 834228
6. **Verify**: Role selection screen shows:
   - ✅ Walter White (parent) with lock icon (DISABLED)
   - ✅ "Parent" section header
   - ✅ Jesse Pinkman in "Siblings" section (selectable)
   - ✅ Cannot tap/select Walter White
7. Select Jesse Pinkman
8. **Verify**: App navigates to child dashboard
9. **Verify**: Walter White's name displayed as parent in UI
10. **Verify**: Dashboard shows only Jesse's tasks

### Test 4: Task Upload and Approval Flow
**Scenario**: Child completes task, parent approves

**Steps**:
1. Log in as Jesse Pinkman (child)
2. Navigate to Tasks tab
3. Select a task and complete it
4. Upload photo proof
5. Submit task
6. **Verify**: Task shows "Pending Review"
7. Log out and log in as Walter White (parent)
8. **Verify**: Task appears in "Pending Approvals" on dashboard
9. **Verify**: Task is attributed to Jesse Pinkman
10. Tap on task and approve it
11. **Verify**: Task is approved
12. Log out and log in as Jesse Pinkman
13. **Verify**: Task shows as "Approved"
14. **Verify**: Screen time balance increased

### Test 5: Activity Tab Data Isolation
**Scenario**: Parent views child activity

**Steps**:
1. Log in as Walter White (parent)
2. Navigate to Activity/Children tab
3. Select Jesse Pinkman
4. **Verify**: Activity logs show only Jesse's data
5. **Verify**: Screen time metrics show only Jesse's data
6. **Verify**: Task completion history shows only Jesse's data
7. **Verify**: No data from other households appears
8. **Verify**: No legacy test profiles (Sarah, Jake) appear

### Test 6: Data Isolation After Reset
**Scenario**: Ensure clean state after onboarding reset

**Steps**:
1. Complete onboarding as Walter White
2. View children (should see Jesse Pinkman)
3. Reset onboarding (Settings > Debug & Testing)
4. Complete onboarding again as Walter White
5. **Verify**: NO legacy test profiles appear
6. **Verify**: ONLY household 834228 data is visible
7. **Verify**: Household context properly reset and reloaded

## Technical Implementation Details

### Profile Selection Logic

**Parent Flow (ParentOnboardingCoordinator)**:
```swift
private func linkDeviceToProfile(_ profile: Profile) {
    let selectedRole: UserRole = profile.role == "parent" ? .parent : .child
    let deviceMode = DeviceModeService.deviceModeFromUserRole(selectedRole)
    DeviceModeService.shared.setDeviceMode(deviceMode)
    // Skip certain onboarding steps since joining existing household
    OnboardingManager.shared.hasCompletedNameEntry = true
    OnboardingManager.shared.hasCompletedFamilySetup = true
}
```

**Child Flow (ChildOnboardingCoordinator)**:
```swift
private func linkDeviceToProfile(_ profile: Profile) {
    // Always sets device mode to CHILD
    let childMode = DeviceModeService.deviceModeFromUserRole(.child)
    DeviceModeService.shared.setDeviceMode(childMode)
    // Skip parent-only steps
    OnboardingManager.shared.hasCompletedNameEntry = true
    OnboardingManager.shared.hasCompletedFamilySetup = true
}
```

### Household Context Integration

When user signs in or profile is loaded:
```swift
// In AuthenticationService.loadProfile()
if let householdIdString = response.householdId,
   let householdId = UUID(uuidString: householdIdString) {
    let parentId: UUID? = response.role == "parent" ? UUID(uuidString: response.id) : nil
    HouseholdContext.shared.setHouseholdContext(
        householdId: householdId,
        parentId: parentId
    )
}
```

### Task Filtering

Tasks are automatically filtered by household:
```swift
// In TaskService.getPendingApprovals()
let householdTasks = householdContext.filterTasksForHousehold(allPendingTasks) { task in
    task.childId
}
```

## Files Modified

1. `EnviveNew/Services/Household/HouseholdService.swift` - Added getAllProfilesByInviteCode()
2. `EnviveNew/Views/Onboarding/ChildProfileSelectorView.swift` - Enhanced with parent profile display
3. `EnviveNew/EnviveNewApp.swift` - Updated onboarding flow routing

## Files Created

1. `EnviveNew/Views/Onboarding/ParentProfileSelectorView.swift` - New profile selector for parents
2. `EnviveNew/Views/Onboarding/ParentOnboardingCoordinator.swift` - New coordinator for parent join flow

## Known Limitations

1. Parents can select child profiles - this is intentional for troubleshooting
2. Profile switching requires re-onboarding (could be improved with in-app profile switcher)
3. Multiple households per device not yet supported

## Future Enhancements

1. Add in-app profile switcher for testing without full re-onboarding
2. Support multiple households per device
3. Add profile creation during onboarding for new households
4. Enhanced profile management (edit, delete, transfer)
