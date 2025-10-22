# Mode Switcher Name Fix

## Issues Fixed

### Issue 1: Child Profile Shows Parent's Name
**Problem:** When switching from parent (Sullivan) to child (Mike Wazowski), the child profile displayed the parent's name instead of the child's name.

**Root Cause:** The `ProfileView` uses `@AppStorage("userName")` which is a global UserDefaults value that wasn't being updated when switching modes.

**Solution:** Update `userName` in UserDefaults when switching modes to reflect the current user's actual name.

### Issue 2: Parent Name Not Persisting
**Problem:** When switching back from child to parent mode, the parent had to re-enter their name instead of it being pre-filled.

**Root Cause:** The parent's name wasn't being saved and restored across mode switches.

**Solution:** Implemented a saved parent name system that:
- Saves parent name when first entering it
- Preserves it when switching to child mode
- Restores it automatically when switching back to parent

## Changes Made

### 1. Enhanced State Management

```swift
// Added saved parent name state
@State private var savedParentName: String = "" // Store parent name when switching to child
```

### 2. Improved Initialization

```swift
init(deviceModeManager: LocalDeviceModeManager) {
    // Load parent name from multiple sources
    let parentProfile = deviceModeManager.getProfile(byMode: .parent)
    let savedName = parentProfile?.name ?? ""

    // Also try OnboardingManager
    let onboardingName = OnboardingManager.shared.parentName ?? ""
    let finalName = savedName.isEmpty ? onboardingName : savedName

    _parentName = State(initialValue: finalName)
    _savedParentName = State(initialValue: finalName)
}
```

### 3. Updated Mode Switch Logic

```swift
private func handleModeSwitch() {
    if selectedMode == .parent {
        let trimmedName = parentName.trimmingCharacters(in: .whitespaces)

        // Save parent name for future switches
        savedParentName = trimmedName
        UserDefaults.standard.set(trimmedName, forKey: "savedParentName")

        // Update UserDefaults for ProfileView
        UserDefaults.standard.set(trimmedName, forKey: "userName")

    } else if let childId = selectedChildId, let child = availableChildren.first(...) {
        // Save parent name before switching
        if !savedParentName.isEmpty {
            UserDefaults.standard.set(savedParentName, forKey: "savedParentName")
        }

        // Update UserDefaults with child's info
        UserDefaults.standard.set(childName, forKey: "userName")
        UserDefaults.standard.set(childAge, forKey: "userAge")
    }
}
```

### 4. Restore Parent Name on Appear

```swift
.onAppear {
    loadAvailableChildren()

    // Restore saved parent name when opening switcher
    if let savedName = UserDefaults.standard.string(forKey: "savedParentName"),
       !savedName.isEmpty {
        savedParentName = savedName
        if deviceModeManager.isChildMode() && selectedMode == .parent {
            parentName = savedName
        } else if parentName.isEmpty {
            parentName = savedName
        }
    }
}
```

### 5. Auto-Fill Parent Name When Selected

```swift
// Parent mode button
Button(action: {
    selectedMode = .parent
    selectedChildId = nil

    // Restore saved parent name when selecting parent mode
    if parentName.isEmpty && !savedParentName.isEmpty {
        parentName = savedParentName
    }
}) { ... }
```

## How It Works Now

### Switching Parent → Child

1. User opens switcher (shows parent name: "Sullivan")
2. Selects "Child" mode
3. Picks child "Mike Wazowski" (age 8)
4. Taps "Switch to Child Mode"
5. **Result:**
   - Profile now shows "Mike Wazowski" ✅
   - Age shows 8 ✅
   - Parent name "Sullivan" saved for later

### Switching Child → Parent

1. User opens switcher (currently in child mode)
2. Selects "Parent" mode
3. **Parent name field automatically shows "Sullivan"** ✅
4. User can edit if needed, or just tap "Switch to Parent Mode"
5. **Result:**
   - Profile shows "Sullivan" ✅
   - No need to re-enter name ✅

## Data Flow

```
Parent Mode (Sullivan)
   ↓
Save "Sullivan" to:
  - savedParentName (state)
  - UserDefaults "savedParentName"
  - UserDefaults "userName"
   ↓
Switch to Child Mode (Mike Wazowski)
   ↓
Update UserDefaults:
  - "userName" = "Mike Wazowski"
  - "userAge" = 8
   ↓
ProfileView displays "Mike Wazowski" ✅
   ↓
Open switcher again
   ↓
Restore from UserDefaults "savedParentName"
   ↓
parentName = "Sullivan" (pre-filled)
   ↓
Switch back to Parent
   ↓
UserDefaults "userName" = "Sullivan"
   ↓
ProfileView displays "Sullivan" ✅
```

## Testing

### Test Case 1: Parent → Child Name Display

1. **As Parent:** Sullivan
2. **Switch to Child:** Mike Wazowski (age 8)
3. **Check ProfileView:** Should show "Mike Wazowski", not "Sullivan"
4. **Expected:** ✅ Child's name displayed correctly

### Test Case 2: Child → Parent Name Persistence

1. **Currently:** Child mode (Mike Wazowski)
2. **Open Switcher**
3. **Select Parent mode**
4. **Check name field:** Should be pre-filled with "Sullivan"
5. **Switch to Parent**
6. **Check ProfileView:** Should show "Sullivan"
7. **Expected:** ✅ Parent name restored automatically

### Test Case 3: Multiple Switches

1. Parent (Sullivan) → Child (Mike) → Parent (Sullivan) → Child (Boo) → Parent
2. **Expected:** Each switch shows correct name in ProfileView
3. **Expected:** Parent name always "Sullivan" when switching back

### Test Case 4: Edit Parent Name

1. Switch to Parent
2. Change name from "Sullivan" to "James P. Sullivan"
3. Switch to Child
4. Switch back to Parent
5. **Expected:** Name field shows "James P. Sullivan" (updated name)

## UserDefaults Keys Used

| Key | Purpose | Example Value |
|-----|---------|---------------|
| `savedParentName` | Stores parent's name across switches | "Sullivan" |
| `userName` | Current user's display name (used by ProfileView) | "Mike Wazowski" or "Sullivan" |
| `userAge` | Current user's age (used by ProfileView) | 8 |

## Console Logging

Look for these logs to verify the fix:

```
✅ Correct behavior:
🔄 Switched to Child mode: Mike Wazowski, Age: 8
🔄 Switched to Parent mode: Sullivan

❌ Old behavior (fixed):
🔄 Switched to Child mode: Mike Wazowski, Age: 8
   [ProfileView still shows "Sullivan"] ← FIXED
🔄 Switched to Parent mode:
   [Name field empty, must re-enter] ← FIXED
```

## Files Modified

✅ `EnviveNew/Views/Shared/ModeSwitcherView.swift`
  - Lines 14-36: Enhanced initialization with name persistence
  - Lines 77-91: Added .onAppear to restore saved parent name
  - Lines 181-189: Auto-fill parent name when selecting parent mode
  - Lines 405-466: Updated handleModeSwitch with UserDefaults updates

## Benefits

**Before:**
- ❌ Child profile showed parent's name (confusing!)
- ❌ Had to re-enter parent name every time switching back
- ❌ No name persistence across mode switches

**After:**
- ✅ Child profile shows child's actual name
- ✅ Parent name automatically restored when switching back
- ✅ Seamless mode switching experience
- ✅ UserDefaults keeps ProfileView in sync

## Related Issues

This fix ensures that:
- ProfileView always displays the correct user's name
- Mode switching is smooth and doesn't lose information
- Testing parent-child workflows is easier (no re-entering names)

---

**Status:** ✅ Complete
**Date:** 2025-10-21
**Impact:** Mode switcher now correctly displays and persists names for both parent and child modes
