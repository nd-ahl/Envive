-- ============================================
-- FIX DATA INTEGRITY ISSUES
-- Run this to fix common data sync issues between tables
-- ============================================

\echo '=========================================='
\echo 'FIXING DATA INTEGRITY ISSUES'
\echo '=========================================='
\echo ''

-- 1. Create profiles for orphaned auth users
\echo '1️⃣ Creating profiles for orphaned auth users...'

INSERT INTO profiles (id, email, full_name, role, created_at, updated_at)
SELECT
    u.id,
    u.email,
    COALESCE(
        u.raw_user_meta_data->>'full_name',
        u.raw_user_meta_data->>'name',
        'User'
    ),
    COALESCE(u.raw_user_meta_data->>'role', 'parent'),
    u.created_at,
    NOW()
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

SELECT
    COUNT(*) as profiles_created,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ No orphaned users found'
        ELSE '✅ Created profiles for orphaned users'
    END as status
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;

\echo ''

-- 2. Sync household_id in profiles with household_members
\echo '2️⃣ Syncing household_id from household_members to profiles...'

UPDATE profiles p
SET household_id = hm.household_id, updated_at = NOW()
FROM household_members hm
WHERE p.id = hm.user_id
  AND (p.household_id IS NULL OR p.household_id != hm.household_id);

SELECT
    COUNT(*) as profiles_synced,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ All profiles already in sync'
        ELSE '✅ Synced household_id for profiles'
    END as status
FROM profiles p
JOIN household_members hm ON p.id = hm.user_id
WHERE p.household_id IS NULL OR p.household_id != hm.household_id;

\echo ''

-- 3. Create missing household_members entries
\echo '3️⃣ Creating missing household_members entries...'

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
    WHERE hm.user_id = p.id AND hm.household_id = p.household_id
  )
ON CONFLICT (household_id, user_id) DO NOTHING;

SELECT
    COUNT(*) as members_created,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ No missing household_members entries'
        ELSE '✅ Created missing household_members entries'
    END as status
FROM profiles p
WHERE p.household_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM household_members hm
    WHERE hm.user_id = p.id AND hm.household_id = p.household_id
  );

\echo ''

-- 4. Remove orphaned household_members (where profile doesn't exist)
\echo '4️⃣ Removing orphaned household_members...'

DELETE FROM household_members hm
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = hm.user_id
);

SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '✅ No orphaned household_members'
        ELSE '⚠️ Removed orphaned household_members'
    END as status
FROM household_members hm
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = hm.user_id
);

\echo ''

-- 5. Fix mismatched roles between profiles and household_members
\echo '5️⃣ Syncing roles between profiles and household_members...'

UPDATE household_members hm
SET role = p.role
FROM profiles p
WHERE hm.user_id = p.id
  AND hm.role != p.role;

SELECT
    COUNT(*) as roles_synced,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ All roles already in sync'
        ELSE '✅ Synced roles between tables'
    END as status
FROM household_members hm
JOIN profiles p ON hm.user_id = p.id
WHERE hm.role != p.role;

\echo ''

-- 6. Verify data integrity after fixes
\echo '6️⃣ Verifying data integrity...'

-- Check 1: All auth users have profiles
SELECT
    '✅ Auth users → profiles' as check_name,
    COUNT(*) as issues_found
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Check 2: All profiles with household_id have household_members entry
SELECT
    '✅ Profiles → household_members' as check_name,
    COUNT(*) as issues_found
FROM profiles p
WHERE p.household_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM household_members hm
    WHERE hm.user_id = p.id AND hm.household_id = p.household_id
  );

-- Check 3: All household_members have matching profiles
SELECT
    '✅ Household_members → profiles' as check_name,
    COUNT(*) as issues_found
FROM household_members hm
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = hm.user_id
);

-- Check 4: Roles match between tables
SELECT
    '✅ Role consistency' as check_name,
    COUNT(*) as issues_found
FROM household_members hm
JOIN profiles p ON hm.user_id = p.id
WHERE hm.role != p.role;

-- Check 5: household_id matches between tables
SELECT
    '✅ Household_id consistency' as check_name,
    COUNT(*) as issues_found
FROM household_members hm
JOIN profiles p ON hm.user_id = p.id
WHERE p.household_id IS NULL OR p.household_id != hm.household_id;

\echo ''
\echo '=========================================='
\echo '✅ DATA INTEGRITY FIX COMPLETE'
\echo '=========================================='
\echo ''
\echo 'Run verify_parent_child_setup.sql to confirm everything is working.'
\echo ''
