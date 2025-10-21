-- ============================================
-- MIGRATION 008: CLEANUP TEST DATA FOR BETA LAUNCH
-- ============================================
-- Purpose: Remove all legacy test accounts and orphaned data
-- Run this in Supabase SQL Editor before beta launch

-- ============================================
-- 1. IDENTIFY TEST ACCOUNTS
-- ============================================

-- List all test accounts before deletion (for verification)
SELECT id, full_name, email, role, created_at
FROM profiles
WHERE
    -- Test names from development
    full_name IN ('Sarah', 'Jake', 'Child Two', 'Parent', 'Test Parent', 'Test Child')
    OR email LIKE '%test%'
    OR email LIKE '%example%'
    -- Add any other patterns for test accounts
ORDER BY created_at DESC;

-- ============================================
-- 2. BACKUP TEST DATA (Optional)
-- ============================================

-- Uncomment this section if you want to backup test data before deletion
/*
CREATE TABLE IF NOT EXISTS test_data_backup AS
SELECT * FROM profiles
WHERE
    full_name IN ('Sarah', 'Jake', 'Child Two', 'Parent', 'Test Parent', 'Test Child')
    OR email LIKE '%test%'
    OR email LIKE '%example%';
*/

-- ============================================
-- 3. DELETE ORPHANED TASK ASSIGNMENTS
-- ============================================

-- Delete task assignments for test child accounts
DELETE FROM task_assignments
WHERE child_id IN (
    SELECT id FROM profiles
    WHERE full_name IN ('Sarah', 'Jake', 'Child Two', 'Test Child')
);

-- Delete task assignments assigned by test parent accounts
DELETE FROM task_assignments
WHERE assigned_by IN (
    SELECT id FROM profiles
    WHERE full_name IN ('Parent', 'Test Parent')
);

-- ============================================
-- 4. DELETE ORPHANED XP RECORDS
-- ============================================

-- Delete XP records for test accounts
DELETE FROM xp_balances
WHERE user_id IN (
    SELECT id FROM profiles
    WHERE full_name IN ('Sarah', 'Jake', 'Child Two', 'Parent', 'Test Parent', 'Test Child')
       OR email LIKE '%test%'
       OR email LIKE '%example%'
);

-- ============================================
-- 5. DELETE ORPHANED CREDIBILITY RECORDS
-- ============================================

-- Delete credibility records for test accounts
DELETE FROM credibility_scores
WHERE child_id IN (
    SELECT id FROM profiles
    WHERE full_name IN ('Sarah', 'Jake', 'Child Two', 'Test Child')
);

-- ============================================
-- 6. DELETE TEST HOUSEHOLDS
-- ============================================

-- Store test household IDs for cleanup
CREATE TEMP TABLE temp_test_households AS
SELECT DISTINCT household_id
FROM profiles
WHERE
    full_name IN ('Sarah', 'Jake', 'Child Two', 'Parent', 'Test Parent', 'Test Child')
    OR email LIKE '%test%'
    OR email LIKE '%example%';

-- Delete test households (this will cascade delete related data)
DELETE FROM households
WHERE id IN (SELECT household_id FROM temp_test_households);

-- ============================================
-- 7. DELETE TEST PROFILES
-- ============================================

-- Delete test profiles from auth.users (if they exist)
-- Note: This requires superuser privileges or service_role
-- Run this separately if needed
/*
DELETE FROM auth.users
WHERE email LIKE '%test%' OR email LIKE '%example%';
*/

-- Delete test profiles from profiles table
DELETE FROM profiles
WHERE
    full_name IN ('Sarah', 'Jake', 'Child Two', 'Parent', 'Test Parent', 'Test Child')
    OR email LIKE '%test%'
    OR email LIKE '%example%';

-- ============================================
-- 8. VERIFICATION
-- ============================================

-- Verify test data is gone
SELECT COUNT(*) as remaining_test_profiles
FROM profiles
WHERE
    full_name IN ('Sarah', 'Jake', 'Child Two', 'Parent', 'Test Parent', 'Test Child')
    OR email LIKE '%test%'
    OR email LIKE '%example%';

-- Should return 0

-- Check for orphaned records
SELECT 'Orphaned Task Assignments' as check_type, COUNT(*) as count
FROM task_assignments
WHERE child_id NOT IN (SELECT id FROM profiles WHERE role = 'child')
   OR assigned_by NOT IN (SELECT id FROM profiles WHERE role = 'parent')

UNION ALL

SELECT 'Orphaned XP Records', COUNT(*)
FROM xp_balances
WHERE user_id NOT IN (SELECT id FROM profiles)

UNION ALL

SELECT 'Orphaned Credibility Records', COUNT(*)
FROM credibility_scores
WHERE child_id NOT IN (SELECT id FROM profiles WHERE role = 'child');

-- ============================================
-- 9. RESET AUTO-INCREMENT (if applicable)
-- ============================================

-- Note: This is typically not needed for UUID-based tables
-- Include this section if you have any serial/sequence columns

-- ============================================
-- 10. REFRESH STATISTICS
-- ============================================

-- Update table statistics for better query performance
ANALYZE profiles;
ANALYZE households;
ANALYZE task_assignments;
ANALYZE xp_balances;
ANALYZE credibility_scores;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'Migration 008 completed successfully!';
    RAISE NOTICE 'All test data has been removed from the database.';
    RAISE NOTICE 'Please run the verification queries above to confirm.';
END $$;
