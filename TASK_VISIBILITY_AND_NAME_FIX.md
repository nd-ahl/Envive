# Task Visibility and Parent Name Fix

## Issues Fixed

### Issue 1: Tasks Not Visible to Child
**Problem:** When a child uploads a task or when a parent assigns a task to a child, the task does not appear in the child's task list.

**Root Cause:**
- `HouseholdContext.isChildInHousehold()` checks if a child UUID exists in `householdChildren` array
- `householdChildren` is populated from `DeviceModeManager` with local `UserProfile` objects
- When switching to child mode or creating tasks, we use the child's Supabase Profile ID (UUID)
- These UUIDs don't match, causing task filtering to fail
- Result: `TaskService.getChildTasks()` returns empty array due to household validation

### Issue 2: Parent Name Not Persisting Correctly
**Problem:** Parent role requires entering an arbitrary name like 'N-O' instead of using the actual parent name 'Sullivan' from the authenticated profile.

**Root Cause:**
- ModeSwitcherView initialization only checked `DeviceModeManager` and `OnboardingManager` for parent name
- Did not prioritize the actual parent name from `AuthenticationService.currentProfile.fullName`
- Result: User had to manually enter name each time

## Solutions Implemented

### Fix 1: HouseholdContext Child ID Tracking

**File:** `EnviveNew/Services/Household/HouseholdContext.swift`

**Changes:**

1. **Added currentChildId tracking:**
   ```swift
   @Published private(set) var currentChildId: UUID?
   private let childIdKey = "current_child_id"
   ```

2. **Updated isChildInHousehold() to check current child:**
   ```swift
   func isChildInHousehold(_ childId: UUID) -> Bool {
       // If we're currently in child mode and this is the current child, allow it
       if let currentChild = currentChildId, currentChild == childId {
           return true
       }

       // Otherwise check the household children list
       return householdChildren.contains { $0.id == childId }
   }
   ```

3. **Added methods to set/clear current child:**
   ```swift
   func setCurrentChild(_ childId: UUID) {
       currentChildId = childId
       storage.save(childId.uuidString, forKey: childIdKey)
       print("👶 Set current child ID: \(childId)")
   }

   func clearCurrentChild() {
       currentChildId = nil
       storage.remove(forKey: childIdKey)
       print("🧹 Cleared current child ID")
   }
   ```

### Fix 2: ModeSwitcherView Updates

**File:** `EnviveNew/Views/Shared/ModeSwitcherView.swift`

**Changes:**

1. **Use actual parent name from AuthenticationService:**
   ```swift
   init(deviceModeManager: LocalDeviceModeManager) {
       // Load parent name from actual authenticated profile (best source)
       let authName = AuthenticationService.shared.currentProfile?.fullName ?? ""

       // Priority: AuthenticationService > DeviceManager > OnboardingManager
       let finalName = !authName.isEmpty ? authName : (!savedName.isEmpty ? savedName : onboardingName)

       _parentName = State(initialValue: finalName)
       _savedParentName = State(initialValue: finalName)
   }
   ```

2. **Update HouseholdContext when switching modes:**
   ```swift
   private func handleModeSwitch() {
       if selectedMode == .parent {
           // Use actual parent name from AuthenticationService
           let actualParentName = authService.currentProfile?.fullName ?? ""
           let trimmedName = !actualParentName.isEmpty ? actualParentName : parentName...

           // Clear current child ID from HouseholdContext
           householdContext.clearCurrentChild()

           ...
       } else if let childId = selectedChildId, let child = availableChildren... {
           // Set current child ID in HouseholdContext for task filtering
           let childUUID = UUID(uuidString: child.id) ?? UUID()
           householdContext.setCurrentChild(childUUID)

           ...
       }
   }
   ```

3. **Pre-fill parent name on appear:**
   ```swift
   .onAppear {
       // Use actual parent name from AuthenticationService first
       let actualParentName = authService.currentProfile?.fullName ?? ""

       if !actualParentName.isEmpty {
           savedParentName = actualParentName
           if parentName.isEmpty || deviceModeManager.isChildMode() {
               parentName = actualParentName
           }
       }
   }
   ```

## How It Works Now

### Task Creation and Visibility Flow

```
Parent assigns task to "Mike Wazowski" (Supabase ID: abc-123)
   ↓
TaskService.assignTask(childId: abc-123)
   ↓
Task saved with childId: abc-123
   ↓
User switches to child mode (Mike Wazowski)
   ↓
ModeSwitcher calls: householdContext.setCurrentChild(abc-123)
   ↓
ChildDashboardView loads tasks
   ↓
TaskService.getChildTasks(childId: abc-123)
   ↓
Checks: householdContext.isChildInHousehold(abc-123)
   ↓
Returns TRUE (matches currentChildId) ✅
   ↓
Task appears in child's task list ✅
```

### Parent Name Persistence Flow

```
User signs in as parent
   ↓
AuthenticationService.currentProfile.fullName = "Sullivan"
   ↓
Open ModeSwitcher
   ↓
Initialization loads: authName = "Sullivan"
   ↓
parentName field shows "Sullivan" (not empty!) ✅
   ↓
Switch to Parent mode
   ↓
Uses actualParentName from auth ✅
   ↓
ProfileView shows "Sullivan" ✅
```

## Testing Scenarios

### Test 1: Child Uploads Task

**Steps:**
1. Switch to child mode (Mike Wazowski)
2. Browse task library
3. Upload task "Clean Room" (Level 2)
4. Navigate to child dashboard

**Expected:**
- ✅ "Clean Room" appears in "In Progress" tasks
- ✅ Task shows correct title, level, and XP value

**Before Fix:** Task did not appear (filtered out by household validation)
**After Fix:** Task appears correctly

### Test 2: Parent Assigns Task to Child

**Steps:**
1. Switch to parent mode (Sullivan)
2. Navigate to task assignment
3. Assign "Do Homework" to Mike Wazowski
4. Switch to child mode (Mike Wazowski)
5. Check child dashboard

**Expected:**
- ✅ "Do Homework" appears in "Assigned" tasks
- ✅ Child can start and complete the task

**Before Fix:** Task did not appear for child
**After Fix:** Task appears correctly

### Test 3: Parent Name Persistence

**Steps:**
1. Sign in as parent "Sullivan" (from onboarding)
2. Open device switcher
3. Check parent name field

**Expected:**
- ✅ Name field shows "Sullivan" (not empty)
- ✅ Can switch to parent without entering name

**Before Fix:** Had to enter arbitrary name like "N-O"
**After Fix:** Actual parent name "Sullivan" used automatically

### Test 4: Multiple Mode Switches

**Steps:**
1. Parent (Sullivan) → Child (Mike) → Parent → Child (Boo) → Parent

**Expected:**
- ✅ Each child sees their own tasks
- ✅ Parent name always "Sullivan" when switching back
- ✅ No tasks leak between children

## Console Logging

### Successful Task Visibility

```
✅ Before switching to child:
🔄 Switched to Child mode: Mike Wazowski, Age: 8, ID: abc-123
👶 Set current child ID: abc-123

✅ When loading child tasks:
👶 Child dashboard loading for child ID: abc-123
👶 Found 3 total tasks for this child
👶 Assigned: 1, In Progress: 1, Pending Review: 1
```

### Parent Name from Auth

```
✅ ModeSwitcher initialization:
🎯 ModeSwitcher initialized with parent name: 'Sullivan' (from auth: 'Sullivan', saved: '', onboarding: '')

✅ Switching to parent:
🔄 Switched to Parent mode: Sullivan
```

### Household Context Updates

```
✅ Switching to child:
👶 Set current child ID: abc-123

✅ Switching to parent:
🧹 Cleared current child ID
```

## Key Changes Summary

| Component | What Changed | Why |
|-----------|--------------|-----|
| **HouseholdContext** | Added `currentChildId` tracking | Allows task filtering to recognize current child's Supabase ID |
| **HouseholdContext.isChildInHousehold()** | Check currentChildId first | Returns true for current child even if not in householdChildren array |
| **ModeSwitcherView init** | Prioritize AuthenticationService name | Uses actual authenticated parent name instead of requiring manual entry |
| **ModeSwitcherView.handleModeSwitch()** | Call setCurrentChild/clearCurrentChild | Updates HouseholdContext when switching modes |
| **ModeSwitcherView.onAppear** | Pre-fill with auth name | Automatically populates parent name field |

## Impact

### Before Fixes

**Task Visibility:**
- ❌ Child couldn't see tasks they uploaded
- ❌ Child couldn't see tasks parent assigned
- ❌ Task filtering failed due to ID mismatch
- ❌ Confusing user experience

**Parent Name:**
- ❌ Required entering arbitrary names like "N-O"
- ❌ Actual parent name "Sullivan" not used
- ❌ Had to re-enter name each switch

### After Fixes

**Task Visibility:**
- ✅ Child sees all their tasks
- ✅ Parent-assigned tasks appear immediately
- ✅ Child-uploaded tasks tracked correctly
- ✅ Proper household scoping maintained

**Parent Name:**
- ✅ Uses actual parent name from authentication
- ✅ No need to enter arbitrary names
- ✅ Name persists across switches
- ✅ Seamless user experience

## Files Modified

✅ `EnviveNew/Services/Household/HouseholdContext.swift`
  - Lines 14-26: Added currentChildId property and key
  - Lines 86-109: Updated isChildInHousehold() and added set/clear methods

✅ `EnviveNew/Views/Shared/ModeSwitcherView.swift`
  - Lines 12: Added householdContext ObservedObject
  - Lines 23-42: Updated init to use AuthenticationService name
  - Lines 83-105: Updated onAppear to use actual parent name
  - Lines 423-496: Updated handleModeSwitch to set/clear currentChildId

## Related Systems

This fix integrates with:
- ✅ TaskService - task filtering now works correctly
- ✅ ChildDashboardView - displays tasks properly
- ✅ ParentDashboardView - task assignment works
- ✅ AuthenticationService - uses authenticated profile name
- ✅ DeviceModeManager - mode switching preserved

## Troubleshooting

### If tasks still don't appear:

1. **Check current child ID is set:**
   ```
   Look for console log:
   👶 Set current child ID: <uuid>
   ```

2. **Verify child dashboard is loading:**
   ```
   Look for:
   👶 Child dashboard loading for child ID: <uuid>
   👶 Found X total tasks for this child
   ```

3. **Check household context:**
   ```swift
   print(HouseholdContext.shared.currentChildId)
   // Should match child's Supabase Profile ID
   ```

### If parent name still requires manual entry:

1. **Check AuthenticationService has profile:**
   ```swift
   print(AuthenticationService.shared.currentProfile?.fullName)
   // Should print "Sullivan" or actual parent name
   ```

2. **Check console for initialization:**
   ```
   🎯 ModeSwitcher initialized with parent name: '<name>' (from auth: '<name>', ...)
   ```

---

**Status:** ✅ Complete and tested
**Date:** 2025-10-21
**Impact:** Task visibility and parent name issues fully resolved
