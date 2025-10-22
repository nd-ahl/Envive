# Apply and Verify Parent-Child Setup

## Step 1: Apply the Migration

Go to your Supabase Dashboard → SQL Editor and run:

```sql
-- Copy and paste the contents of:
-- database/migrations/009_comprehensive_parent_child_setup.sql
```

This migration will:
- ✅ Ensure all required table columns exist (age, avatar_url)
- ✅ Create/update the `handle_new_user()` trigger function
- ✅ Set up RLS policies for parent-child linking
- ✅ Allow parents to create and manage child profiles
- ✅ Create helper functions for querying household data
- ✅ Add performance indexes

## Step 2: Verify the Setup

Run the verification script:

```sql
-- Copy and paste the contents of:
-- database/verify_parent_child_setup.sql
```

This will check:
- ✅ Trigger function exists and is active
- ✅ RLS policies are properly configured
- ✅ No orphaned users (auth.users without profiles)
- ✅ Data integrity between tables
- ✅ Recent profile creations

## Step 3: Test Parent-Child Creation Flow

### Test 1: Create a Parent Account
```swift
// This should automatically create a profile via trigger
let profile = try await AuthenticationService.shared.signUp(
    email: "parent@test.com",
    password: "test123",
    fullName: "Test Parent",
    role: .parent
)
```

**Expected:** Profile created automatically with role="parent"

### Test 2: Create a Household
```swift
let household = try await HouseholdService.shared.createHousehold(
    name: "Test Family",
    createdBy: parentProfile.id
)
```

**Expected:**
- Household created with unique invite_code
- Parent's profile updated with household_id
- Parent added to household_members table

### Test 3: Create a Child Profile
```swift
let childId = try await HouseholdService.shared.createChildProfile(
    name: "Test Child",
    age: 8,
    householdId: household.id,
    createdBy: parentProfile.id,
    avatarUrl: nil
)
```

**Expected:**
- Child profile created in profiles table (no auth.users entry)
- Child's household_id matches parent's household
- Child added to household_members table

### Test 4: Fetch Household Data After Login
```swift
// After parent logs in
let profile = try await AuthenticationService.shared.signIn(
    email: "parent@test.com",
    password: "test123"
)

// Get household
let household = try await HouseholdService.shared.getUserHousehold(
    userId: profile.id
)

// Get all household members (including children)
let members = try await HouseholdService.shared.getHouseholdMembers(
    householdId: household.id
)

// Filter children only
let children = members.filter { $0.role == "child" }
```

**Expected:**
- Parent sees their household info
- Parent sees all household members (parents + children)
- HouseholdContext is set with householdId and parentId

## Step 4: Verify Data Isolation

Each user should only see data from their household:

```swift
// After login, check HouseholdContext
print("Household ID: \(HouseholdContext.shared.currentHouseholdId)")
print("Parent ID: \(HouseholdContext.shared.currentParentId)")
print("Children: \(HouseholdContext.shared.householdChildren.count)")
```

**RLS Policies ensure:**
- Users can only view profiles in their household
- Parents can only create/edit children in their household
- Children can only see other members in their household

## Troubleshooting

### Issue: Auth user created but no profile
**Solution:** The trigger may not be running. Check:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

If missing, run migration 009 again.

### Issue: Parent cannot create child profiles
**Solution:** Check RLS policies allow INSERT for child role:
```sql
SELECT policyname, cmd, with_check
FROM pg_policies
WHERE tablename = 'profiles' AND cmd = 'INSERT';
```

Should show policy allowing `role = 'child'` without `auth.uid() = id` check.

### Issue: Child profile has no household_id
**Solution:** Ensure you're passing householdId when creating:
```swift
let childId = try await HouseholdService.shared.createChildProfile(
    name: "Child Name",
    age: 8,
    householdId: household.id,  // ← Must provide this
    createdBy: parentProfile.id
)
```

### Issue: Data from other households is visible
**Solution:** RLS policies may be too permissive. Check:
```sql
SELECT * FROM pg_policies WHERE tablename IN ('profiles', 'households', 'household_members');
```

All SELECT policies should filter by household_id.

## What Happens After Login

```
1. User signs in (email/password or Apple)
   ↓
2. AuthenticationService.loadProfile(userId) is called
   ↓
3. Profile is fetched from Supabase (with household_id)
   ↓
4. HouseholdContext.setHouseholdContext(householdId, parentId) is called
   ↓
5. All subsequent queries are scoped to that household
   ↓
6. User sees only their household data
```

## Summary

✅ **Migration 009** sets up the complete parent-child infrastructure
✅ **Verification script** confirms everything is working
✅ **RLS policies** ensure data isolation between households
✅ **Triggers** automatically create profiles for new auth users
✅ **HouseholdContext** maintains current user's household scope
✅ **Parent-child linking** allows parents to manage children in their household

Your app is now ready for multi-household, parent-child functionality! 🎉
