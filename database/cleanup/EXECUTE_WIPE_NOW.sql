-- ============================================
-- APPROVED: COMPLETE USER DATA WIPE
-- User confirmed: YES, WIPE ALL DATA
-- Execution Date: 2025-10-27
-- ============================================

-- STEP 1: View current data (before deletion)
-- ============================================

SELECT '=== BEFORE WIPE - DATA SNAPSHOT ===' as info;

SELECT 'Total Households:' as metric, COUNT(*) as count FROM households;
SELECT 'Total Profiles:' as metric, COUNT(*) as count FROM profiles;
SELECT 'Total Household Members:' as metric, COUNT(*) as count FROM household_members;
SELECT 'Total Auth Users:' as metric, COUNT(*) as count FROM auth.users;

SELECT '' as spacer;
SELECT '=== HOUSEHOLDS TO DELETE ===' as info;
SELECT id, name, invite_code, created_at FROM households;

SELECT '' as spacer;
SELECT '=== PROFILES TO DELETE ===' as info;
SELECT id, email, full_name, role, household_id FROM profiles;

SELECT '' as spacer;
SELECT '=== AUTH USERS TO DELETE ===' as info;
SELECT id, email, created_at FROM auth.users;

-- ============================================
-- STEP 2: EXECUTE DELETION (UNCOMMENTED - READY TO RUN)
-- ============================================

-- Delete all household members first (no foreign key dependencies)
DELETE FROM household_members;

-- Delete all profiles (references households, not auth.users due to CASCADE direction)
DELETE FROM profiles;

-- Delete all households
DELETE FROM households;

-- Delete task verifications (if table exists - will error gracefully if not)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'task_verifications') THEN
        DELETE FROM task_verifications;
    END IF;
END $$;

-- ============================================
-- STEP 3: DELETE AUTH USERS
-- ============================================
-- CRITICAL: This allows Apple ID re-use
-- Note: This may fail due to Supabase Auth restrictions
-- If it fails, you MUST delete users manually from dashboard

DELETE FROM auth.users;

-- If the above fails with an error, see MANUAL_AUTH_DELETION.md

-- ============================================
-- STEP 4: VERIFY COMPLETE DELETION
-- ============================================

SELECT '' as spacer;
SELECT '=== AFTER WIPE - VERIFICATION ===' as info;

SELECT 'Remaining Households:' as metric, COUNT(*) as count FROM households;
SELECT 'Remaining Profiles:' as metric, COUNT(*) as count FROM profiles;
SELECT 'Remaining Household Members:' as metric, COUNT(*) as count FROM household_members;
SELECT 'Remaining Auth Users:' as metric, COUNT(*) as count FROM auth.users;

-- SUCCESS CRITERIA:
-- All counts above should be 0
-- If auth.users count > 0, proceed to manual deletion

SELECT '' as spacer;
SELECT CASE
    WHEN (SELECT COUNT(*) FROM households) = 0
     AND (SELECT COUNT(*) FROM profiles) = 0
     AND (SELECT COUNT(*) FROM household_members) = 0
    THEN '✅ WIPE SUCCESSFUL - Application data deleted'
    ELSE '❌ WIPE INCOMPLETE - Some data remains'
END as status;

SELECT CASE
    WHEN (SELECT COUNT(*) FROM auth.users) = 0
    THEN '✅ AUTH USERS DELETED - Apple ID can be re-used'
    ELSE '⚠️ AUTH USERS REMAIN - Manual deletion required from dashboard'
END as auth_status;

-- ============================================
-- NEXT STEPS AFTER SUCCESSFUL WIPE
-- ============================================
-- 1. If auth.users count > 0, go to Supabase Dashboard > Authentication > Users
-- 2. Manually delete all users
-- 3. Sign out of app on device
-- 4. Sign in with Apple ID (will create fresh account)
-- 5. Complete onboarding from scratch
