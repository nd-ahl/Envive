-- ============================================
-- VERIFY PARENT-CHILD SETUP
-- Run this in Supabase SQL Editor to check everything is working
-- ============================================

\echo '=========================================='
\echo 'PARENT-CHILD SETUP VERIFICATION'
\echo '=========================================='
\echo ''

-- 1. Check if handle_new_user function exists
\echo '1️⃣ Checking handle_new_user function...'
SELECT
    CASE
        WHEN COUNT(*) > 0 THEN '✅ handle_new_user function EXISTS'
        ELSE '❌ handle_new_user function MISSING'
    END as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'handle_new_user' AND n.nspname = 'public';

\echo ''

-- 2. Check if trigger is active
\echo '2️⃣ Checking on_auth_user_created trigger...'
SELECT
    CASE
        WHEN COUNT(*) > 0 THEN '✅ on_auth_user_created trigger ACTIVE'
        ELSE '❌ on_auth_user_created trigger MISSING'
    END as status,
    MAX(tgenabled) as enabled
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

\echo ''

-- 3. Check profiles table structure
\echo '3️⃣ Checking profiles table structure...'
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

\echo ''

-- 4. Check RLS policies on profiles
\echo '4️⃣ Checking RLS policies on profiles table...'
SELECT
    policyname as "Policy Name",
    cmd as "Command",
    CASE
        WHEN permissive = 'PERMISSIVE' THEN '✅ Permissive'
        ELSE '⚠️ Restrictive'
    END as "Type"
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

\echo ''

-- 5. Check RLS policies on household_members
\echo '5️⃣ Checking RLS policies on household_members table...'
SELECT
    policyname as "Policy Name",
    cmd as "Command",
    CASE
        WHEN permissive = 'PERMISSIVE' THEN '✅ Permissive'
        ELSE '⚠️ Restrictive'
    END as "Type"
FROM pg_policies
WHERE tablename = 'household_members'
ORDER BY cmd, policyname;

\echo ''

-- 6. Check if RLS is enabled
\echo '6️⃣ Checking RLS status...'
SELECT
    tablename as "Table",
    CASE
        WHEN rowsecurity THEN '✅ ENABLED'
        ELSE '❌ DISABLED'
    END as "RLS Status"
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'households', 'household_members')
ORDER BY tablename;

\echo ''

-- 7. Check for orphaned auth users (users without profiles)
\echo '7️⃣ Checking for orphaned auth users...'
SELECT
    COUNT(*) as orphaned_count,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ No orphaned users'
        ELSE '⚠️ Found users without profiles'
    END as status
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Show orphaned users if any
SELECT
    u.id,
    u.email,
    u.created_at,
    '❌ NO PROFILE' as status
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL
LIMIT 5;

\echo ''

-- 8. Check recent profile creations
\echo '8️⃣ Recent profile creations (last 5)...'
SELECT
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.household_id,
    p.age,
    p.created_at,
    CASE
        WHEN p.household_id IS NOT NULL THEN '✅ In household'
        ELSE '⏳ No household yet'
    END as household_status
FROM profiles p
ORDER BY p.created_at DESC
LIMIT 5;

\echo ''

-- 9. Check household structure
\echo '9️⃣ Checking household structure (with members)...'
SELECT
    h.name as "Household",
    h.invite_code as "Invite Code",
    COUNT(DISTINCT hm.user_id) as "Total Members",
    COUNT(DISTINCT CASE WHEN p.role = 'parent' THEN hm.user_id END) as "Parents",
    COUNT(DISTINCT CASE WHEN p.role = 'child' THEN hm.user_id END) as "Children"
FROM households h
LEFT JOIN household_members hm ON h.id = hm.household_id
LEFT JOIN profiles p ON hm.user_id = p.id
GROUP BY h.id, h.name, h.invite_code
ORDER BY h.created_at DESC
LIMIT 5;

\echo ''

-- 10. Check for data integrity issues
\echo '🔟 Checking data integrity...'

-- Check for profiles with household_id but no household_members entry
SELECT
    COUNT(*) as profiles_missing_membership,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ All profiles with household_id have household_members entry'
        ELSE '⚠️ Some profiles missing household_members entry'
    END as status
FROM profiles p
WHERE p.household_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM household_members hm
    WHERE hm.user_id = p.id AND hm.household_id = p.household_id
  );

-- Check for household_members without matching profile household_id
SELECT
    COUNT(*) as members_with_mismatched_household,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ All household_members have matching profile household_id'
        ELSE '⚠️ Some household_members have mismatched household_id'
    END as status
FROM household_members hm
JOIN profiles p ON hm.user_id = p.id
WHERE p.household_id IS NULL OR p.household_id != hm.household_id;

\echo ''
\echo '=========================================='
\echo '✅ VERIFICATION COMPLETE'
\echo '=========================================='
\echo ''
\echo 'SUMMARY OF WHAT SHOULD BE IN PLACE:'
\echo '  ✓ handle_new_user() function exists'
\echo '  ✓ on_auth_user_created trigger is active'
\echo '  ✓ RLS is enabled on all tables'
\echo '  ✓ Policies allow parents to create child profiles'
\echo '  ✓ Policies allow viewing household members'
\echo '  ✓ No orphaned auth users'
\echo '  ✓ Data integrity checks pass'
\echo ''
