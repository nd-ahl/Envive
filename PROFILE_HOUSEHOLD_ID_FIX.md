# Profile Household ID Fix

## Issue Description

**Problem**: When entering a household invite code during onboarding, only child profiles appear in the profile selection screen. Parent profiles are missing.

**Root Cause**: Some parent profiles in the database are missing the `household_id` field. This happens when:
1. The household was created before the profile update code was working properly
2. There was a database update failure during household creation
3. The `household_id` field was not properly set when the parent created the household

## Technical Details

### Expected Behavior
When a household is created:
1. `HouseholdService.createHousehold()` is called
2. Household record is inserted into `households` table
3. Creator is added to `household_members` table
4. Creator's profile is updated with `household_id` via `updateUserHousehold()`
5. Profile should now have `household_id` set

### Actual Issue
In some cases, step 4 fails or is incomplete, resulting in:
- Profile exists in `household_members` table ✓
- Profile record in `profiles` table has `household_id: NULL` ✗

### Query Impact
When `getAllProfilesByInviteCode()` queries for profiles:
```swift
let profiles = try await supabase
    .from("profiles")
    .select()
    .eq("household_id", value: household.id)  // This returns 0 results if household_id is NULL
```

## Solution Implemented

### 1. Fallback Query Mechanism
Enhanced `getAllProfilesByInviteCode()` to use a two-step approach:

**Step 1**: Query profiles directly by `household_id` (fast path)
```swift
let profiles = try await supabase
    .from("profiles")
    .select()
    .eq("household_id", value: household.id)
```

**Step 2**: If no profiles found, query via `household_members` table (fallback)
```swift
// Get member IDs from household_members
let members = try await supabase
    .from("household_members")
    .select()
    .eq("household_id", value: household.id)

// Load each member's profile
for member in members {
    let profile = try await supabase
        .from("profiles")
        .select()
        .eq("id", value: member.userId)

    // FIX: Update profile with household_id if missing
    if profile.householdId == nil {
        try await updateUserHousehold(userId: profile.id, householdId: household.id)
    }
}
```

### 2. Bulk Fix Utility
Added `fixProfileHouseholdIds()` method to fix ALL profiles in the database:

```swift
func fixProfileHouseholdIds() async throws {
    // Get all household members
    let allMembers = try await supabase
        .from("household_members")
        .select()

    // For each member, ensure their profile has household_id set
    for member in allMembers {
        let profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: member.userId)

        // Update if missing or incorrect
        if profile.householdId == nil || profile.householdId != member.householdId {
            try await updateUserHousehold(userId: profile.id, householdId: member.householdId)
        }
    }
}
```

### 3. Debug UI Button
Added "Fix Profile Household IDs" button in Settings → Debug & Testing section

## How to Use the Fix

### Option 1: Automatic Fix During Onboarding (Recommended)
The fix is now automatic! When a user enters an invite code:
1. App queries for profiles with `household_id`
2. If none found, app automatically:
   - Queries `household_members` table
   - Loads profiles for each member
   - Updates missing `household_id` fields
   - Returns all profiles (parent + child)

**No manual intervention needed**

### Option 2: Manual Fix for All Profiles (Database Maintenance)
To fix ALL profiles in the database at once:

1. Open the app
2. Navigate to Settings tab (parent or child)
3. Scroll to "Debug & Testing" section
4. Tap "Fix Profile Household IDs"
5. Check Xcode console for results:
   ```
   🔧 Starting profile household_id fix...
   📋 Found X total household members
     🔧 Fixing: Walter White - setting household_id to abc-123
     🔧 Fixing: Jesse Pinkman - setting household_id to abc-123
   ✅ Fixed X profile(s)
   ```

## Testing the Fix

### Test 1: Verify Parent Profile Now Appears
1. Reset onboarding
2. Start onboarding flow as "Parent"
3. Choose "Join Household"
4. Enter household invite code (e.g., 834228)
5. **Expected**: Profile selection screen now shows:
   - ✅ Walter White (parent) - should appear!
   - ✅ Jesse Pinkman (child)
6. Select parent profile
7. **Expected**: Navigate to parent dashboard

### Test 2: Verify Debug Fix Works
1. Go to Settings → Debug & Testing
2. Tap "Fix Profile Household IDs"
3. Check Xcode console output
4. **Expected**: See which profiles were fixed
5. Try onboarding flow again
6. **Expected**: All profiles appear correctly

### Test 3: Verify Child Flow Still Works
1. Reset onboarding
2. Start onboarding as "Child"
3. Enter household code
4. **Expected**:
   - Parent profile visible but disabled 🔒
   - Child profiles selectable
5. Select child profile
6. **Expected**: Navigate to child dashboard

## Database Schema Reference

### profiles table
```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    role TEXT,  -- 'parent' or 'child'
    household_id TEXT,  -- Should match household.id
    avatar_url TEXT,
    age INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### household_members table
```sql
CREATE TABLE household_members (
    household_id TEXT,
    user_id TEXT,
    role TEXT,  -- 'parent' or 'child'
    joined_at TIMESTAMP
);
```

### Correct State
For a profile to appear in household queries:
- `profiles.household_id` = `households.id` ✓
- `household_members.household_id` = `households.id` ✓
- `household_members.user_id` = `profiles.id` ✓

## Files Modified

1. **`EnviveNew/Services/Household/HouseholdService.swift`**
   - Enhanced `getAllProfilesByInviteCode()` with fallback mechanism
   - Added `fixProfileHouseholdIds()` utility method
   - Added better logging for debugging

2. **`EnviveNew/Views/Shared/RootNavigationView.swift`**
   - Added "Fix Profile Household IDs" button in Debug & Testing section

## Prevention

To prevent this issue in the future, ensure:
1. `createHousehold()` always calls `updateUserHousehold()`
2. `joinHousehold()` always calls `updateUserHousehold()`
3. Database triggers could be added to auto-sync `household_id` from `household_members`
4. Regular data integrity checks via `fixProfileHouseholdIds()`

## Verification Checklist

After applying the fix, verify:
- [ ] Parent profiles appear in profile selection screen
- [ ] Child profiles still appear correctly
- [ ] Parent can select their own profile
- [ ] Parent can select child profiles (for troubleshooting)
- [ ] Child can only select child profiles
- [ ] Parent profiles show as disabled for children
- [ ] Database console shows no errors
- [ ] `household_id` is set on all profiles

## Future Enhancements

1. **Database Trigger**: Auto-sync `household_id` when `household_members` is updated
2. **Data Validation**: Background job to check data integrity
3. **Migration Script**: One-time migration to fix all existing profiles
4. **Error Handling**: Better error messages if profile update fails
