# Troubleshooting: "No Profiles Found" Error

You're seeing "no profile found" after entering the household code. Let's diagnose and fix this step by step.

## Quick Diagnosis Checklist

Run through these checks in order:

---

## Step 1: Did You Apply the Database Migration?

**CRITICAL**: The migration file I created needs to be run on your Supabase database.

### Option A: Using Supabase CLI (Recommended)
```bash
cd /Users/nealahlstrom/github/Envive
supabase db push
```

### Option B: Manual SQL Execution
1. Go to https://app.supabase.com
2. Select your project: `vevcxsjcqwlmmlchfymn`
3. Go to **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy the ENTIRE contents of:
   `/Users/nealahlstrom/github/Envive/database/migrations/007_allow_unauthenticated_child_profile_lookup.sql`
6. Paste into the SQL Editor
7. Click **Run** (or press Cmd+Enter)

**Expected Output:**
```
DROP POLICY
CREATE POLICY
CREATE POLICY
```

---

## Step 2: Verify RLS Policies Exist

Run this query in Supabase SQL Editor:

```sql
SELECT
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;
```

**Expected Results:**

You should see these policies:
1. ✅ `Authenticated users can view household profiles` - roles: `{authenticated}` - cmd: `SELECT`
2. ✅ `Public can view child profiles` - roles: `{anon}` - cmd: `SELECT`
3. ✅ `Users can insert profiles` - cmd: `INSERT`
4. ✅ `Users can update profiles in their household` - cmd: `UPDATE`

**If you DON'T see "Public can view child profiles":**
- ❌ Migration was NOT applied
- Go back to Step 1 and apply the migration

---

## Step 3: Check if Child Profiles Were Actually Created

Run this query in Supabase SQL Editor:

```sql
-- Check all profiles in database
SELECT
    id,
    email,
    full_name,
    role,
    household_id,
    age,
    created_at
FROM profiles
ORDER BY created_at DESC;
```

**What to look for:**

✅ **Good**: You see entries like:
```
id: a1b2c3...  | email: null | full_name: Emma | role: child | household_id: xyz123... | age: 8
id: d4e5f6...  | email: null | full_name: Liam | role: child | household_id: xyz123... | age: 10
```

❌ **Bad**: No child profiles exist
- This means the parent's "Add Profiles" step failed
- Check console logs for errors during profile creation

---

## Step 4: Verify Household Invite Code

Run this query (replace `123456` with your actual code):

```sql
SELECT
    h.id,
    h.name,
    h.invite_code,
    p.full_name,
    p.role,
    p.age
FROM households h
LEFT JOIN profiles p ON p.household_id = h.id
WHERE h.invite_code = '123456' -- CHANGE THIS
ORDER BY p.role, p.full_name;
```

**Expected Output:**
```
id: xyz123...  | name: Smith Family | invite_code: 123456 | full_name: Alice | role: parent | age: null
id: xyz123...  | name: Smith Family | invite_code: 123456 | full_name: Emma  | role: child  | age: 8
id: xyz123...  | name: Smith Family | invite_code: 123456 | full_name: Liam  | role: child  | age: 10
```

**If NO RESULTS:**
- ❌ The household doesn't exist or the invite code is wrong
- Check what code you're entering vs. what's in the database

**If ONLY PARENT (no children):**
- ❌ Child profiles weren't created successfully
- Check console logs when parent added profiles

---

## Step 5: Test Anonymous Access (Simulates the Child Login)

This is the CRITICAL test. Run this in Supabase SQL Editor:

```sql
-- Simulate unauthenticated user (like child entering code)
SET ROLE anon;

-- Try to query child profiles (this is what the app does)
SELECT
    id,
    full_name,
    role,
    household_id,
    age
FROM profiles
WHERE role = 'child';

RESET ROLE;
```

**Expected Output:**
✅ You should see ALL child profiles in the database

**If NO RESULTS:**
❌ The RLS policy is BLOCKING anonymous access
- The migration wasn't applied correctly
- Go back to Step 1

---

## Step 6: Check App Console Logs

When you enter the household code in the app, check the Xcode console for these messages:

**Good logs:**
```
🔍 Searching for household with invite code: 123456
✅ Found household: Smith Family (ID: xyz123...)
🔍 Searching for child profiles in household: xyz123...
✅ Found 2 child profile(s):
  - Name: Emma, Age: 8, ID: a1b2c3...
  - Name: Liam, Age: 10, ID: d4e5f6...
```

**Bad logs:**
```
🔍 Searching for household with invite code: 123456
❌ Failed to load child profiles: [error message]
```

**If you see an error**, look for:
- `"new row violates row-level security"` → RLS policy blocking query
- `"relation does not exist"` → Table/column name issue
- `"could not find household"` → Invalid invite code

---

## Step 7: Run Complete Diagnostic

I've created a comprehensive diagnostic script. Run this in Supabase SQL Editor:

**File:** `/Users/nealahlstrom/github/Envive/database/diagnostics/check_child_profiles.sql`

1. Open the file
2. **IMPORTANT**: Change line 75: `test_code TEXT := '123456';` to YOUR actual household code
3. Copy entire contents
4. Paste into Supabase SQL Editor
5. Run

This will check:
- RLS policies
- Households
- Profiles
- Household members
- Anonymous access
- Specific invite code lookup

---

## Common Issues & Fixes

### Issue 1: Migration Not Applied
**Symptoms:**
- No "Public can view child profiles" policy
- Anonymous query returns 0 results

**Fix:**
```bash
# Apply migration manually
cd /Users/nealahlstrom/github/Envive
psql [your-supabase-connection-string] < database/migrations/007_allow_unauthenticated_child_profile_lookup.sql
```

Or use Supabase Dashboard SQL Editor (see Step 1 Option B)

---

### Issue 2: Child Profiles Not Created
**Symptoms:**
- No child entries in `profiles` table
- Only parent profile exists

**Fix:**
1. Check console logs when parent clicks "Save & Continue" in AddProfilesView
2. Look for errors like:
   - `❌ Failed to create profile for Emma: ...`
   - `"insert or update on table profiles violates foreign key constraint"`

3. Common causes:
   - Parent's `household_id` is NULL
   - RLS INSERT policy blocking creation
   - Network error

4. Manual test - run as authenticated parent:
   ```sql
   -- First, get parent's household_id
   SELECT id, household_id FROM profiles WHERE role = 'parent' LIMIT 1;

   -- Then try to create child profile
   INSERT INTO profiles (id, full_name, role, household_id, age, created_at, updated_at)
   VALUES (
     gen_random_uuid()::text,
     'Test Child',
     'child',
     '[paste-household-id-here]',
     8,
     NOW(),
     NOW()
   );
   ```

---

### Issue 3: Wrong Invite Code
**Symptoms:**
- Query finds no household

**Fix:**
```sql
-- Find what codes actually exist
SELECT invite_code, name, created_at
FROM households
ORDER BY created_at DESC;
```

Make sure you're entering the exact code shown in the parent's LinkDevicesView.

---

### Issue 4: Household ID Mismatch
**Symptoms:**
- Household exists
- Child profiles exist
- But they're in DIFFERENT households

**Fix:**
```sql
-- Check which household each profile belongs to
SELECT
    p.full_name,
    p.role,
    p.household_id,
    h.name as household_name,
    h.invite_code
FROM profiles p
LEFT JOIN households h ON h.id = p.household_id
ORDER BY p.created_at DESC;
```

If child profiles have `household_id = NULL` or different household_id than parent:
```sql
-- Fix: Update child profiles to correct household
UPDATE profiles
SET household_id = '[correct-household-id]'
WHERE role = 'child'
AND (household_id IS NULL OR household_id != '[correct-household-id]');
```

---

## Step 8: Nuclear Option - Fresh Start

If nothing works, let's recreate everything:

```sql
-- 1. Delete all existing data (CAREFUL!)
DELETE FROM household_members;
DELETE FROM profiles WHERE role = 'child';
DELETE FROM households;

-- 2. Sign out of the app
-- 3. Delete app and reinstall
-- 4. Create new parent account
-- 5. Create new household
-- 6. Add child profiles
-- 7. Test child login with new code
```

---

## What Should Happen (Happy Path)

**Parent Side:**
1. Parent creates account → `profiles` table gets entry with `role='parent'`
2. Parent creates household → `households` table gets entry with random `invite_code`
3. Parent's profile updated with `household_id`
4. Parent adds child "Emma, age 8" → `profiles` table gets entry:
   - `id`: random UUID (NOT from auth.users)
   - `email`: NULL
   - `full_name`: "Emma"
   - `role`: "child"
   - `household_id`: same as parent's
   - `age`: 8
5. Parent sees 6-digit code on LinkDevicesView

**Child Side:**
1. Child enters 6-digit code → Query: `SELECT * FROM households WHERE invite_code = ?`
2. Find household_id → Store for next query
3. Query child profiles → `SELECT * FROM profiles WHERE household_id = ? AND role = 'child'`
   - **This query must work WITHOUT authentication** → Requires RLS policy "Public can view child profiles"
4. Child sees "Emma, age 8" in list
5. Child selects Emma → Device linked to Emma's profile ID

---

## Still Not Working?

If you've tried everything above, please share:

1. **Output from Step 5** (anonymous access test)
2. **Output from Step 6** (app console logs)
3. **Screenshot** of the "no profiles found" screen
4. **This query result:**
   ```sql
   SELECT COUNT(*) FROM profiles WHERE role = 'child';
   ```

This will help me pinpoint the exact issue.

---

## Quick Fix Script

If you just want to test if the RLS policy works, run this:

```sql
-- Force-apply the RLS policy
DROP POLICY IF EXISTS "Public can view child profiles" ON profiles;

CREATE POLICY "Public can view child profiles"
  ON profiles FOR SELECT
  TO anon
  USING (role = 'child');

-- Test it
SET ROLE anon;
SELECT full_name, age FROM profiles WHERE role = 'child';
RESET ROLE;
```

If this returns results, the migration is applied correctly!
