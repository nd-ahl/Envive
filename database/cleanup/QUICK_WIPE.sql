-- ============================================
-- QUICK WIPE - COPY THIS ENTIRE FILE
-- Paste into Supabase SQL Editor and click RUN
-- ============================================

-- Show what exists
SELECT '=== BEFORE WIPE ===' as status;
SELECT 'Households:' as table_name, COUNT(*) as count FROM households
UNION ALL
SELECT 'Profiles:', COUNT(*) FROM profiles
UNION ALL
SELECT 'Members:', COUNT(*) FROM household_members
UNION ALL
SELECT 'Auth Users:', COUNT(*) FROM auth.users;

-- Execute deletion
DELETE FROM household_members;
DELETE FROM profiles;
DELETE FROM households;
DELETE FROM auth.users;

-- Verify deletion
SELECT '=== AFTER WIPE ===' as status;
SELECT 'Households:' as table_name, COUNT(*) as count FROM households
UNION ALL
SELECT 'Profiles:', COUNT(*) FROM profiles
UNION ALL
SELECT 'Members:', COUNT(*) FROM household_members
UNION ALL
SELECT 'Auth Users:', COUNT(*) FROM auth.users;

-- Final status
SELECT CASE
  WHEN (SELECT COUNT(*) FROM auth.users) = 0
  THEN '✅ COMPLETE - All data wiped, Apple ID can be re-used'
  ELSE '⚠️ INCOMPLETE - Delete auth users manually from Dashboard > Authentication > Users'
END as final_status;
