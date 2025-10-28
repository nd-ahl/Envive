-- ============================================
-- COMPLETE USER DATA WIPE
-- WARNING: This will delete ALL user data from the database
-- This allows the same Apple ID to be used to create a fresh account
-- ============================================
--
-- PURPOSE: Reset database to allow re-registration with same Apple ID
--
-- IMPACT: This script will permanently delete:
--   1. All profiles (parent and child)
--   2. All households and invite codes
--   3. All household memberships
--   4. All task verifications (if any)
--   5. Associated auth.users entries (CASCADE)
--
-- DOES NOT DELETE:
--   - Database schema/structure
--   - Triggers and functions
--   - RLS policies
--
-- ============================================

-- STEP 1: Show current data (for confirmation)
-- ============================================

SELECT '=== CURRENT DATA SNAPSHOT ===' as info;

SELECT 'HOUSEHOLDS:' as section;
SELECT id, name, invite_code, created_by, created_at
FROM households
ORDER BY created_at DESC;

SELECT 'PROFILES:' as section;
SELECT id, email, full_name, role, household_id, created_at
FROM profiles
ORDER BY created_at DESC;

SELECT 'HOUSEHOLD MEMBERS:' as section;
SELECT hm.household_id, h.name as household_name, p.full_name, p.role, hm.joined_at
FROM household_members hm
LEFT JOIN households h ON h.id = hm.household_id
LEFT JOIN profiles p ON p.id = hm.user_id
ORDER BY hm.joined_at DESC;

SELECT 'AUTH USERS:' as section;
SELECT id, email, created_at, last_sign_in_at
FROM auth.users
ORDER BY created_at DESC;

-- ============================================
-- STEP 2: DELETE ALL DATA
-- ============================================

-- IMPORTANT: Run this block ONLY after reviewing the data above
-- Uncomment the lines below to execute the wipe

/*

-- Delete all household members
DELETE FROM household_members;

-- Delete all profiles (CASCADE will NOT delete auth.users due to ON DELETE CASCADE direction)
DELETE FROM profiles;

-- Delete all households
DELETE FROM households;

-- Delete task verifications if table exists
DELETE FROM task_verifications WHERE true;

-- CRITICAL: Delete auth.users last
-- This is the auth table - deleting here allows Apple ID re-use
-- Note: Supabase may prevent this depending on RLS policies
-- If this fails, you may need to delete users from Supabase Auth dashboard
DELETE FROM auth.users;

*/

-- ============================================
-- STEP 3: VERIFY DELETION
-- ============================================

SELECT '=== POST-WIPE VERIFICATION ===' as info;

SELECT 'Remaining households:' as section, COUNT(*) as count FROM households;
SELECT 'Remaining profiles:' as section, COUNT(*) as count FROM profiles;
SELECT 'Remaining household_members:' as section, COUNT(*) as count FROM household_members;
SELECT 'Remaining auth.users:' as section, COUNT(*) as count FROM auth.users;

-- If counts are 0, wipe was successful
-- If auth.users count > 0, you may need to delete from Supabase dashboard

-- ============================================
-- ADDITIONAL INFO
-- ============================================

-- To re-enable the account after wipe:
-- 1. Ensure all counts above are 0
-- 2. Sign in with Apple ID again
-- 3. App will create fresh profile and household
-- 4. Onboarding will run from scratch
