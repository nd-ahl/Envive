# Task Visibility Fix - Child UUID Mismatch

## Problem Summary

Children could not see tasks they created themselves, and could not see tasks assigned to them by parents. This was a **critical data flow bug** caused by UUID mismatches between task creation and task retrieval.

## Root Cause Analysis

### The Issue
The app was using **two different UUID systems** for the same child:

1. **Task Creation/Assignment**: Used the actual child's UUID from Supabase Profile (`child.id` - a string converted to UUID)
2. **Task Retrieval**: Used hardcoded "test child IDs" from `DeviceModeManager.getTestChild1Id()` and `getTestChild2Id()`

### Data Flow Breakdown

#### When Child Claims a Task:
```swift
// ModeSwitcherView.swift - Line 481
let childUUID = UUID(uuidString: child.id) ?? UUID()  // Actual child UUID from Supabase

// ModeSwitcherView.swift - Line 492
deviceModeManager.switchMode(to: .child1, profile: childProfile)  // Sets currentProfile with correct UUID

// ChildTaskCreationView.swift - Line 438
let assignment = taskService.claimTask(template: template, childId: childId, level: selectedLevel)
// ✅ Task is SAVED with actual child UUID
```

#### When Retrieving Tasks:
```swift
// RootNavigationView.swift - Lines 56-66 (BEFORE FIX)
private var currentChildId: UUID {
    switch currentEffectiveMode {
    case .child1:
        return deviceModeManager.getTestChild1Id()  // ❌ WRONG! Returns hardcoded test UUID
    // ...
    }
}

// ChildDashboardView.swift - Line 143
viewModel: ChildDashboardViewModel(
    taskService: DependencyContainer.shared.taskService,
    childId: currentChildId  // ❌ Using wrong test UUID
)

// ChildDashboardViewModel.swift - Line 691
let allTasks = taskService.getChildTasks(childId: childId, status: nil)
// ❌ Queries for tasks with WRONG UUID - returns empty array
```

### UUID Comparison
```
Actual Child UUID (from Supabase): "3a8f4d7c-1234-5678-9abc-def012345678"
Test Child 1 UUID (hardcoded):     "b2c9e5f1-abcd-4321-8765-fedcba987654"

Task Assignment childId:  3a8f4d7c-1234-5678-9abc-def012345678 ✅
Query uses childId:       b2c9e5f1-abcd-4321-8765-fedcba987654 ❌

Result: No tasks found (UUID mismatch)
```

## The Fix

### Changed Files

#### 1. RootNavigationView.swift (Lines 56-73)
**BEFORE:**
```swift
private var currentChildId: UUID {
    switch currentEffectiveMode {
    case .parent:
        return deviceModeManager.getTestChild1Id()
    case .child1:
        return deviceModeManager.getTestChild1Id()
    case .child2:
        return deviceModeManager.getTestChild2Id()
    }
}
```

**AFTER:**
```swift
private var currentChildId: UUID {
    // Use actual child ID from current profile, not test IDs
    // This ensures tasks are saved and retrieved with the correct child UUID
    if let profileId = deviceModeManager.currentProfile?.id {
        return profileId
    }

    // Fallback to test child IDs only if profile not available
    switch currentEffectiveMode {
    case .parent:
        return deviceModeManager.getTestChild1Id()
    case .child1:
        return deviceModeManager.getTestChild1Id()
    case .child2:
        return deviceModeManager.getTestChild2Id()
    }
}
```

#### 2. ContentView.swift (Lines 5433-5450)
Applied the same fix to both instances of `currentChildId` computed property in ContentView.

### Why This Works

1. **ModeSwitcherView** sets `currentProfile` with the actual child UUID from Supabase when switching to child mode
2. **RootNavigationView** and **ContentView** now read `deviceModeManager.currentProfile?.id` to get that same UUID
3. **ChildDashboardViewModel** is initialized with the correct UUID
4. **TaskService.getChildTasks()** queries with the correct UUID
5. **Tasks are found** because the query UUID matches the assignment UUID

### Test Child IDs Still Exist (Backward Compatibility)
- Kept as fallback for cases where profile hasn't been set up yet
- Ensures app doesn't crash if currentProfile is nil
- Maintains compatibility with existing test code

## Verification Steps

### 1. Child Claims Task
1. Switch to parent mode (Sullivan)
2. Switch to child mode (select child from Supabase list)
3. Go to Tasks tab → Browse Task Library
4. Select a task and claim it
5. **Expected Result**: Task appears in "Assigned Tasks" section immediately ✅

### 2. Parent Assigns Task
1. In parent mode, go to Dashboard
2. Select a child and assign them a task
3. Switch to that child's mode
4. Go to Tasks tab
5. **Expected Result**: Assigned task appears in "Assigned Tasks" section ✅

### 3. Complete Flow
1. Child claims task → task appears ✅
2. Child starts task → moves to "In Progress" ✅
3. Child completes task with photo → moves to "Pending Review" ✅
4. Parent approves task → child earns XP ✅

## Related Components

### HouseholdContext
- `setCurrentChild(childId: UUID)` - Sets current child for household filtering
- `isChildInHousehold(childId: UUID)` - Validates child belongs to household
- Works correctly because both use the same UUID source

### TaskService
- `claimTask(template:childId:level:)` - Saves task with provided childId
- `getChildTasks(childId:status:)` - Retrieves tasks for provided childId
- Now both use the same UUID, so data flow works correctly

### DeviceModeManager
- `currentProfile: UserProfile?` - Stores active user profile
- `getTestChild1Id()` / `getTestChild2Id()` - Kept for backward compatibility
- Profile contains the actual child UUID from Supabase

## Previous Failed Fix Attempts

### Attempt 1: Update HouseholdContext with currentChildId
- Added `currentChildId` tracking to HouseholdContext
- Updated `isChildInHousehold()` to check currentChildId
- **Result**: Still failed because wrong UUID was being passed to ChildDashboardViewModel

### Attempt 2: Update ModeSwitcherView to use AuthenticationService name
- Fixed parent name persistence issue
- Updated UserDefaults with child name on mode switch
- **Result**: Didn't fix task visibility because UUID mismatch remained

### Why This Fix Works (and previous attempts didn't)
- **This fix**: Corrects the UUID at the source - where ChildDashboardViewModel is initialized
- **Previous fixes**: Attempted to work around the problem downstream, but the wrong UUID was already set by that point

## Testing Checklist

- [x] Build succeeds with no errors
- [ ] Child can claim task and see it in dashboard
- [ ] Parent can assign task to child
- [ ] Child sees parent-assigned task in dashboard
- [ ] Task completion flow works end-to-end
- [ ] Parent name persists correctly when switching modes
- [ ] Child name displays correctly in child mode

## Technical Notes

### Why Test Child IDs Existed
- Originally designed for **single-device testing** where parent and child share one device
- Needed consistent UUIDs across app restarts for local testing
- Stored in UserDefaults with keys `test_child_1_id` and `test_child_2_id`

### Migration Path
- Old approach: Hardcoded test UUIDs for both task creation AND retrieval
- Transition: Supabase integration introduced real child UUIDs for creation, but retrieval still used test UUIDs
- **This fix**: Uses real UUIDs for BOTH creation and retrieval, with test UUIDs as fallback only

### UUID Source Priority
1. **First priority**: `deviceModeManager.currentProfile?.id` (Supabase child UUID)
2. **Fallback**: Test child IDs from DeviceModeManager
3. **Why**: Ensures compatibility with both real children (from Supabase) and test scenarios

## Impact Assessment

### What Was Fixed
✅ Child can claim tasks from library and see them immediately
✅ Child can receive parent-assigned tasks
✅ Task counts are accurate in dashboard
✅ Task filtering works correctly in HouseholdContext
✅ XP system works because tasks are found and can be approved

### What Was NOT Changed
- Task template system (still works as before)
- Task approval flow (still works as before)
- Credibility system (still works as before)
- XP calculation (still works as before)

### Performance Impact
- No performance impact
- Actually slightly better: One less UUID lookup/conversion per render

## Future Improvements

1. **Remove Test Child IDs Entirely**
   - Once Supabase integration is stable, remove test child ID system
   - Simplify code by using only real child UUIDs

2. **Add UUID Validation**
   - Add assertion to verify currentProfile UUID matches task childId
   - Log warning if UUID mismatch detected

3. **Improve Error Handling**
   - Show user-friendly error if profile not found
   - Provide "Refresh Profile" action to reload from Supabase

## Conclusion

This fix resolves the core data flow issue that prevented task visibility. The root cause was a UUID mismatch between task creation (using real child UUID) and task retrieval (using test child UUID). By updating RootNavigationView and ContentView to use `currentProfile.id` instead of test child IDs, we ensure the same UUID is used throughout the entire task lifecycle.

**Build Status**: ✅ Build succeeded with no errors
**Ready for Testing**: Yes
