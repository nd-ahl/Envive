# Device Switcher Guide

## Overview

The Device Switcher is a testing feature that allows you to switch between Parent and Child modes on a single device. This is essential for testing the full app experience without needing multiple physical devices.

## How to Access

### Via Floating Button

1. **Launch the app** and complete onboarding
2. **Look for the floating button** in the top-right area of the screen
   - It shows the current mode (e.g., "Parent" or child's name)
   - Has a blue background with a switcher icon
3. **Tap the button** to open the Mode Switcher sheet
4. **Drag the button** to reposition it anywhere on screen

### Via Settings (Alternative)

- Navigate to **Parent Settings** → Tap the mode indicator at the top

## Using the Switcher

### Switching to Parent Mode

1. Open the Device Switcher
2. Select **"Parent"** mode
3. Enter your parent name (e.g., "Mom", "Dad", "John")
4. Tap **"Switch to Parent Mode"**
5. The app will immediately switch to Parent view

### Switching to Child Mode

1. Open the Device Switcher
2. Select **"Child"** mode
3. **Select a child** from the list of children in your household
   - Children are loaded from Supabase
   - Shows name and age for each child
4. Tap **"Switch to Child Mode"**
5. The app will switch to Child view for that specific child

## What Happens When You Switch

### Parent Mode

**You can:**
- ✅ View all children in your household
- ✅ Assign tasks to children
- ✅ Approve completed tasks
- ✅ Monitor credibility scores
- ✅ Manage screen time limits
- ✅ View household activity

**Tabs:**
- Dashboard
- Screen Time
- Children
- Activity
- Settings

### Child Mode

**You can:**
- ✅ View assigned tasks
- ✅ Complete tasks and earn XP
- ✅ Spend earned screen time
- ✅ View your credibility score
- ✅ See social activity
- ✅ Manage your profile

**Tabs:**
- Home
- Tasks
- Social
- Profile

## Key Features

### Household Scoping

- **Only shows children from your household**
- Fetches data directly from Supabase database
- Children created during onboarding are automatically available
- Ensures testing reflects real multi-user scenarios

### Data Persistence

- Each mode maintains its own state
- Switching back preserves previous context
- Tasks created by parent appear for assigned children
- XP and screen time are tracked per-child

### Floating Button

- **Draggable** - Move it anywhere on screen
- **Persistent** - Position saved between app launches
- **Smart** - Shows current user's name
- **Locked Mode** - Grays out when role is locked (production)

## Testing Workflows

### Test Task Assignment Flow

1. **Switch to Parent mode**
2. Create a task for a specific child
3. **Switch to that Child mode**
4. Complete the task
5. **Switch back to Parent**
6. Approve the completed task

### Test Screen Time Flow

1. **Switch to Child mode**
2. Complete tasks to earn XP
3. Spend XP for screen time
4. **Switch to Parent mode**
5. View screen time activity

### Test Multi-Child Household

1. **During onboarding**, create multiple child profiles
2. **Switch between different children**
3. Verify each child sees only their own:
   - Tasks
   - XP balance
   - Screen time
   - Activity feed

## Limitations

### Testing Mode Only

- Device switcher is for **development and testing**
- In production, each device will have a fixed role
- Role can be locked during onboarding

### No Auth Context Switching

- Switcher changes UI mode only
- Does not change Supabase authentication
- All modes use the parent's auth session
- Children profiles are non-auth profiles in database

### Single Household

- Only shows children from current parent's household
- Cannot switch between different households
- Must reset onboarding to change households

## Troubleshooting

### "No children available"

**Problem:** Cannot switch to child mode because no children are listed.

**Solution:**
1. Ensure you completed onboarding and added child profiles
2. Check that children were created in Supabase:
   - Run `database/diagnostics/verify_children_after_onboarding.sql`
   - Verify `profiles` table has child entries
3. Check parent has `household_id` set
4. Reload children: Close and reopen the switcher

### Children not loading

**Problem:** Switcher shows "Loading children..." indefinitely.

**Solution:**
1. Check console for errors:
   ```
   ❌ Error loading children: <error message>
   ```
2. Verify parent is signed in:
   ```swift
   print(AuthenticationService.shared.currentProfile?.id)
   ```
3. Verify household exists:
   ```swift
   print(AuthenticationService.shared.currentProfile?.householdId)
   ```
4. Run data integrity fix:
   ```bash
   # In Supabase SQL Editor
   # Run: database/fix_data_integrity.sql
   ```

### Switcher button disappeared

**Problem:** Cannot find the floating button.

**Solution:**
1. Button may be off-screen - look at screen edges
2. Reset button position:
   ```swift
   // In Settings → Debug & Testing
   // Or reset via UserDefaults:
   UserDefaults.standard.removeObject(forKey: "modeSwitcherButtonX")
   UserDefaults.standard.removeObject(forKey: "modeSwitcherButtonY")
   ```
3. Check if switcher is enabled:
   ```swift
   @AppStorage("enableDeviceSwitcher") var enableSwitcher = true
   ```

### Mode doesn't switch

**Problem:** Tapped "Switch to X Mode" but nothing happens.

**Solution:**
1. Check role is not locked:
   - Locked roles show a lock icon 🔒
   - Unlock via: Reset Onboarding in Settings
2. Ensure name is entered (for parent mode)
3. Ensure child is selected (for child mode)
4. Check console for mode switch confirmation:
   ```
   🔄 Switched to Parent mode: John
   ```

## Advanced Usage

### Disabling the Switcher

To hide the switcher button:

```swift
// Set via UserDefaults
UserDefaults.standard.set(false, forKey: "enableDeviceSwitcher")

// Or via AppStorage in Settings
@AppStorage("enableDeviceSwitcher") var enableSwitcher = false
```

### Locking Roles (Production)

To lock a device to a specific role:

1. Complete onboarding normally
2. Role is automatically locked after onboarding
3. Switcher button will show 🔒 and be disabled
4. To unlock: Reset Onboarding from Settings

### Testing with Real Devices

For true multi-device testing:

1. **Parent Device:**
   - Complete onboarding
   - Create household
   - Add child profiles
   - Lock to parent role

2. **Child Device (future):**
   - Complete onboarding
   - Join household with invite code
   - Select child profile
   - Lock to child role

## Console Logging

The switcher provides detailed logging:

```
👶 Loaded 2 children from Supabase
🔄 Switched to Parent mode: Mom
🔄 Switched to Child mode: Sarah
```

Check Xcode console for:
- ✅ Children loaded successfully
- ❌ Errors loading children
- 🔄 Mode switch confirmations

## Related Files

- `ModeSwitcherView.swift` - Main switcher UI
- `ModeSwitcherButton.swift` - Floating button component
- `DeviceModeManager.swift` - Mode state management
- `HouseholdService.swift` - Children data fetching
- `RootNavigationView.swift` - Mode-based navigation

## Summary

The Device Switcher enables:
- ✅ Single-device testing of parent-child workflows
- ✅ Quick switching between roles
- ✅ Real household data from Supabase
- ✅ Accurate multi-user experience testing

Use it during development to test the complete app experience without needing multiple devices!
