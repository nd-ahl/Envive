# Troubleshooting: Children Not Showing After Onboarding

## Problem
After completing onboarding and adding children, the parent dashboard shows "No Children Yet" or an empty children list.

## Root Cause (Fixed)
The `ParentDashboardViewModel` was loading children from the local `HouseholdContext.householdChildren` (which uses the old `UserProfile` model) instead of fetching from Supabase where children are actually stored as `Profile` records.

## Solution Applied

### 1. Updated `ParentDashboardViewModel.swift`
**Changed:** Now fetches children from Supabase using `HouseholdService.getMyChildren()`

**Before:**
```swift
func loadData() {
    let householdChildren = householdContext.householdChildren // Local only!
    children = householdChildren.map { ... }
}
```

**After:**
```swift
func loadData() {
    Task {
        await loadChildrenFromSupabase()
    }
}

private func loadChildrenFromSupabase() async {
    let childProfiles = try await householdService.getMyChildren()
    children = childProfiles.map { profile in
        ChildSummary(
            id: UUID(uuidString: profile.id) ?? UUID(),
            name: profile.fullName ?? "Child",
            credibility: ...,
            xpBalance: ...,
            pendingCount: ...
        )
    }
}
```

### 2. Added `getMyChildren()` to `HouseholdService.swift`
**New method:** Fetches children from Supabase for the current parent's household

```swift
func getMyChildren() async throws -> [Profile] {
    guard let currentProfile = AuthenticationService.shared.currentProfile else {
        throw NSError(...)
    }

    guard let householdId = currentProfile.householdId else {
        return []
    }

    guard currentProfile.role == "parent" else {
        throw NSError(...)
    }

    let profiles: [Profile] = try await supabase
        .from("profiles")
        .select()
        .eq("household_id", value: householdId)
        .eq("role", value: "child")
        .order("full_name", ascending: true)
        .execute()
        .value

    return profiles
}
```

### 3. Enhanced UI with Loading States
Added proper loading and empty states to `ParentDashboardView`:
- ✅ Loading spinner while fetching children
- ✅ "No Children Yet" message if empty
- ✅ Helpful text to guide users

## Verification Steps

### Step 1: Run the Diagnostic Script
In Supabase SQL Editor, run:
```sql
-- database/diagnostics/verify_children_after_onboarding.sql
```

This will show you:
- All households and their members
- All child profiles
- Parent-child relationships
- Any data integrity issues

### Step 2: Check Expected Data
After onboarding, you should see:

**In `profiles` table:**
```
id                  | full_name | role   | household_id        | age
--------------------|-----------|--------|---------------------|----
parent-uuid-here    | John Doe  | parent | household-uuid      | NULL
child1-uuid-here    | Sarah     | child  | household-uuid      | 8
child2-uuid-here    | Jake      | child  | household-uuid      | 10
```

**In `household_members` table:**
```
household_id        | user_id           | role
--------------------|-------------------|--------
household-uuid      | parent-uuid-here  | parent
household-uuid      | child1-uuid-here  | child
household-uuid      | child2-uuid-here  | child
```

### Step 3: Test in the App
1. **Sign in** as a parent who went through onboarding
2. **Navigate** to Parent Dashboard
3. **Expected behavior:**
   - "Loading children..." appears briefly
   - Children Overview section shows all children
   - Children appear in task assignment selector

## Common Issues & Fixes

### Issue 1: Children have `NULL` household_id
**Symptom:** Children created but `household_id` is NULL

**Fix:**
```sql
-- Run database/fix_data_integrity.sql
-- OR manually fix:
UPDATE profiles
SET household_id = (
    SELECT household_id
    FROM household_members
    WHERE household_members.user_id = profiles.id
)
WHERE role = 'child' AND household_id IS NULL;
```

### Issue 2: Children not in `household_members` table
**Symptom:** Child profile exists but not linked to household

**Fix:**
```sql
INSERT INTO household_members (household_id, user_id, role, joined_at)
SELECT
    p.household_id,
    p.id,
    p.role,
    p.created_at
FROM profiles p
WHERE p.household_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM household_members hm
    WHERE hm.user_id = p.id
  );
```

### Issue 3: Parent has no household_id
**Symptom:** Parent completed onboarding but household_id is NULL

**Check:**
```sql
SELECT id, email, full_name, role, household_id
FROM profiles
WHERE role = 'parent'
ORDER BY created_at DESC
LIMIT 5;
```

**Fix:** Parent needs to create or join a household during onboarding.

### Issue 4: RLS Policies Blocking Access
**Symptom:** Query succeeds but returns 0 rows due to RLS

**Check:**
```sql
-- Temporarily disable RLS to test (ONLY FOR DEBUGGING)
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
-- Query profiles...
-- Re-enable when done
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
```

**Fix:** Run migration `009_comprehensive_parent_child_setup.sql` to set up correct policies.

## Testing the Fix

### Test 1: Fresh Onboarding
1. Create a new test user account
2. Go through onboarding
3. Create household "Test Family"
4. Add 2 child profiles
5. Complete onboarding
6. **Expected:** Parent dashboard shows 2 children

### Test 2: Existing User
1. Sign in as existing parent
2. Pull down to refresh on Parent Dashboard
3. **Expected:** Children appear after loading

### Test 3: Database Query
```swift
// In Xcode Console, after sign-in:
print("Current user ID: \(AuthenticationService.shared.currentProfile?.id)")
print("Household ID: \(AuthenticationService.shared.currentProfile?.householdId)")

// Then check Supabase:
// SELECT * FROM profiles WHERE household_id = '<household-id>';
```

## Debug Logging

The fix includes extensive logging. Check Xcode console for:

```
🔍 Fetching children for household: <household-uuid>
✅ Found 2 child profile(s)
   - Sarah, Age: 8, ID: <child1-uuid>
   - Jake, Age: 10, ID: <child2-uuid>
📋 Parent dashboard loaded.
📋 Children: Sarah, Jake
```

If you see:
```
⚠️ Current user has no household_id - returning empty children list
```
→ The parent is not properly linked to a household.

## Prevention

To prevent this issue in the future:

1. **Always fetch from Supabase** for household data, not local context
2. **Use `getMyChildren()`** method for parent views
3. **Check `household_id`** is set after household creation
4. **Run verification script** after major onboarding changes
5. **Test with fresh account** after modifying onboarding flow

## Files Changed

1. ✅ `EnviveNew/Views/Parent/ParentDashboardView.swift`
   - Updated `ParentDashboardViewModel.loadData()`
   - Added `loadChildrenFromSupabase()` method
   - Enhanced UI with loading states

2. ✅ `EnviveNew/Services/Household/HouseholdService.swift`
   - Added `getMyChildren()` method

3. ✅ `database/diagnostics/verify_children_after_onboarding.sql`
   - New diagnostic script

4. ✅ `TROUBLESHOOTING_CHILDREN_NOT_SHOWING.md`
   - This guide

## Related Documentation

- `database/apply_and_verify_parent_child_setup.md` - Database setup guide
- `database/migrations/009_comprehensive_parent_child_setup.sql` - Migration
- `Examples/FetchHouseholdDataExample.swift` - Code examples

## Still Having Issues?

1. Run the diagnostic script to check database state
2. Check Xcode console for error messages
3. Verify RLS policies are correct
4. Try running `fix_data_integrity.sql`
5. Check that parent completed onboarding and has household_id set

The fix ensures children are always fetched from Supabase, which is the source of truth for household data. The dashboard will now properly display all children added during onboarding.
