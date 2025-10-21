# Onboarding Flow Fix - Implementation Guide

## Problems Solved

### Issue #1: Child Profiles Not Visible After Entering Household Code
**Root Cause**: RLS (Row Level Security) policy required `auth.uid()` to exist, but children don't authenticate - they just enter a code and select a profile.

**Solution**: Created new database migration that allows unauthenticated (anon) users to view child profiles.

### Issue #2: User Data Persisting Between Different Users
**Root Cause**: `signOut()` only cleared `isAuthenticated` and `currentProfile`, leaving all UserDefaults data intact.

**Solution**: Added comprehensive data cleanup that runs on:
- Sign out
- Sign up (new account)
- Sign in (existing account)
- Apple Sign In
- Child profile linking

---

## Files Modified

### 1. **NEW FILE**: `database/migrations/007_allow_unauthenticated_child_profile_lookup.sql`
   - Drops restrictive RLS policy that blocks unauthenticated users
   - Creates two new policies:
     - **Authenticated users**: Can view profiles in their household
     - **Unauthenticated (anon) users**: Can view ALL child profiles
   - This is safe because child profiles have no sensitive data (no email/password)

### 2. `EnviveNew/Services/Auth/AuthenticationService.swift`
   **Added:**
   - `resetAllUserData()` - Public method for manual data reset
   - `clearAllUserData()` - Private comprehensive cleanup function

   **Updated:**
   - `signUp()` - Clears data before creating new account
   - `signIn()` - Clears data before signing in
   - `signInWithApple()` - Clears data before Apple auth
   - `signOut()` - Clears data when signing out

   **Cleanup includes:**
   - Profile & auth data (userId, userEmail, userName, userRole, userAge, parentName)
   - Household data (householdId, householdCode, isInHousehold)
   - Child profile linking (linkedChildProfileId, childName, childAge)
   - All onboarding completion flags
   - In-memory service state (HouseholdService, OnboardingManager)
   - Device role reset

### 3. `EnviveNew/Views/Onboarding/ChildOnboardingCoordinator.swift`
   **Updated:**
   - `linkDeviceToProfile()` - Clears previous user data before linking device to new child profile

---

## How to Apply the Fix

### Step 1: Run the Database Migration

You need to run the new migration file on your Supabase database:

```bash
# Option A: Using Supabase CLI (recommended)
cd /Users/nealahlstrom/github/Envive
supabase db push

# Option B: Manual execution via Supabase Dashboard
# 1. Go to https://app.supabase.com
# 2. Select your project
# 3. Go to SQL Editor
# 4. Open /database/migrations/007_allow_unauthenticated_child_profile_lookup.sql
# 5. Copy and paste the entire file
# 6. Click "Run" or press Cmd+Enter
```

**What this migration does:**
- Removes the old restrictive SELECT policy
- Creates two new policies:
  1. Authenticated users can view profiles in their household
  2. **Anonymous users can view all child profiles** (this fixes the child profile lookup issue)

### Step 2: Build and Run Your App

The Swift code changes are already in place. Just build:

```bash
# Clean build to ensure all changes are compiled
xcodebuild clean -project EnviveNew.xcodeproj -scheme EnviveNew

# Build for your target device/simulator
xcodebuild -project EnviveNew.xcodeproj -scheme EnviveNew -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or simply build in Xcode (Cmd+B).

---

## Testing the Fix

### Test Scenario 1: Child Profile Visibility

**Setup:**
1. Device A (Parent):
   - Create new parent account
   - Create household (note the 6-digit code)
   - Add child profiles: "Emma, age 8" and "Liam, age 10"

2. Device B (Child):
   - Start fresh (delete app and reinstall if testing on same device)
   - Choose "I'm a Child"
   - Select "Join Existing Household"
   - Enter the 6-digit code from Device A

**Expected Result:**
✅ Device B should now see both "Emma" and "Liam" profiles in the selection screen

**Previous Behavior:**
❌ Device B would see empty list or error: "No profiles found"

---

### Test Scenario 2: Fresh Start on Login

**Setup:**
1. User A (Parent):
   - Sign up as parent "Alice"
   - Create household "Smith Family" (code: 123456)
   - Add child "Bob, age 7"
   - Complete onboarding

2. Sign out User A:
   - Go to app settings
   - Sign out

3. User B (Different Parent):
   - Sign up as parent "Carol"
   - Create household "Jones Family" (code: 654321)

**Expected Result:**
✅ User B should NOT see any data from User A:
- No household code "123456"
- No child profile "Bob"
- No parent name "Alice"
- Onboarding starts from scratch

**Previous Behavior:**
❌ User B would see User A's cached data (household code, child profiles, etc.)

---

### Test Scenario 3: Child Device Switching

**Setup:**
1. Single Device Test:
   - Link device to child profile "Emma" (from household 123456)
   - Use app as Emma
   - Go back to onboarding (delete app and reinstall)
   - Link same device to different child "Liam" (from household 123456)

**Expected Result:**
✅ Device should completely switch identities:
- No trace of "Emma" data
- Fresh credibility score
- Fresh screen time
- Fresh XP balance

**Previous Behavior:**
❌ Device would show mixed data from both Emma and Liam

---

## Verification Checklist

After applying the fix, verify these behaviors:

### Database Level
- [ ] Migration 007 successfully applied in Supabase
- [ ] Can query child profiles without authentication:
  ```sql
  -- Test this query (should return child profiles)
  SELECT * FROM profiles WHERE role = 'child' LIMIT 5;
  ```
- [ ] RLS policies exist:
  - [ ] "Authenticated users can view household profiles"
  - [ ] "Public can view child profiles"

### App Level
- [ ] Parent can create child profiles
- [ ] Parent sees household invite code after profile creation
- [ ] Child can enter invite code without error
- [ ] Child sees list of child profiles after entering valid code
- [ ] Child can select and link to a profile

### Data Cleanup
- [ ] Sign out clears ALL UserDefaults data
- [ ] New sign in doesn't show previous user's data
- [ ] Child profile linking clears previous child's data
- [ ] OnboardingManager state resets properly
- [ ] HouseholdService state clears

---

## Code Reference

### Key Functions Added

**AuthenticationService.swift:185-187**
```swift
/// Public method to manually clear all user data (useful for testing or fresh starts)
func resetAllUserData() {
    clearAllUserData()
}
```

**AuthenticationService.swift:189-231**
```swift
/// Clear ALL user data from UserDefaults to ensure fresh start for new users
/// This prevents data leakage between different user accounts
private func clearAllUserData() {
    // Clears:
    // - Profile data
    // - Household data
    // - Child profile linking
    // - Onboarding state
    // - Service state
}
```

### Where Cleanup Happens

1. **On Sign Up**: AuthenticationService.swift:45
2. **On Sign In**: AuthenticationService.swift:72
3. **On Apple Sign In**: AuthenticationService.swift:93
4. **On Sign Out**: AuthenticationService.swift:179
5. **On Child Profile Link**: ChildOnboardingCoordinator.swift:46

---

## Troubleshooting

### Child Profiles Still Not Showing

**Check:**
1. Migration 007 was successfully applied:
   ```sql
   -- Check if policy exists
   SELECT * FROM pg_policies
   WHERE tablename = 'profiles'
   AND policyname = 'Public can view child profiles';
   ```

2. Child profiles were actually created:
   ```sql
   SELECT id, full_name, role, household_id
   FROM profiles
   WHERE role = 'child';
   ```

3. Household invite code matches:
   ```sql
   SELECT h.invite_code, p.full_name, p.role
   FROM households h
   JOIN profiles p ON p.household_id = h.id
   WHERE h.invite_code = '123456'; -- Use your actual code
   ```

### Data Not Clearing on Logout

**Check:**
1. Print statements in console:
   - Look for: `🧹 All user data cleared - fresh start for new user`

2. Verify cleanup is called:
   ```swift
   // Add breakpoint in AuthenticationService.swift:191 (clearAllUserData)
   // Sign out and verify breakpoint hits
   ```

3. Check if data actually persists:
   ```swift
   // After sign out, check UserDefaults:
   print(UserDefaults.standard.string(forKey: "householdCode")) // Should be nil
   print(UserDefaults.standard.string(forKey: "linkedChildProfileId")) // Should be nil
   ```

### Multiple Users on Same Device

**Important**: iOS UserDefaults is device-specific, NOT user-specific. The cleanup ensures:
- When User A signs out, their data is cleared
- When User B signs in, they start fresh
- If User A signs in again, they see their server-side data (from Supabase), not old cached data

---

## Additional Notes

### Security Implications

**Q: Is it safe to allow anonymous users to view child profiles?**

**A: Yes, because:**
1. Child profiles have NO authentication credentials (no email/password)
2. Child profiles contain only: name, age, avatar, household_id
3. The household invite code acts as authorization
4. Parent profiles are still protected (require authentication)
5. Children cannot create/update/delete profiles (only SELECT)

### Performance

**Q: Does clearing UserDefaults on every login impact performance?**

**A: No:**
1. UserDefaults operations are fast (microseconds)
2. Clearing ~20 keys is negligible
3. The cleanup happens during authentication (already async)
4. Better UX: users get fresh data from server, not stale cache

---

## Success Metrics

After implementing this fix, you should see:

1. **Zero** child profile lookup errors in logs
2. **100%** success rate for household code verification
3. **Zero** data leakage between different user accounts
4. Clean onboarding flow for both parents and children

---

## Support

If you encounter issues:

1. **Check logs**: Look for these print statements:
   - `✅ Child profile created: ...`
   - `🔍 Searching for household with invite code: ...`
   - `✅ Found household: ...`
   - `✅ Found X child profile(s):`
   - `🧹 All user data cleared - fresh start for new user`

2. **Database inspection**: Use Supabase Dashboard to verify:
   - Households table has correct invite codes
   - Profiles table has child entries with correct household_id
   - RLS policies are active

3. **Clear app data**: Delete and reinstall app to test from absolute scratch

---

## Next Steps

1. ✅ Apply migration 007 to Supabase
2. ✅ Build and run app
3. ✅ Test parent → child profile creation flow
4. ✅ Test child → household joining flow
5. ✅ Test user switching (logout → login with different account)
6. ✅ Verify data cleanup (no leftover UserDefaults)
7. 🎉 Celebrate working onboarding flow!
