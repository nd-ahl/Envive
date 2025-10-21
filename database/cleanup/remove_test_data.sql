-- ============================================
-- CLEANUP: Remove all test data except Walter White household and Jesse Pinkman
-- ============================================

-- Walter White household ID: e6c3e9e0-fb24-4f17-97c2-6e06b2b43584
-- Jesse Pinkman profile ID: 10ba587c-ae56-4f38-8621-0aa26f2705bd

-- Step 1: Show what will be kept
SELECT 'HOUSEHOLDS TO KEEP:' as info;
SELECT id, name, invite_code
FROM households
WHERE id = 'e6c3e9e0-fb24-4f17-97c2-6e06b2b43584';

SELECT 'PROFILES TO KEEP:' as info;
SELECT id, full_name, role, age, household_id
FROM profiles
WHERE household_id = 'e6c3e9e0-fb24-4f17-97c2-6e06b2b43584';

-- Step 2: Delete household_members for other households
DELETE FROM household_members
WHERE household_id != 'e6c3e9e0-fb24-4f17-97c2-6e06b2b43584';

-- Step 3: Delete profiles NOT in Walter White household
DELETE FROM profiles
WHERE household_id IS NULL
   OR household_id != 'e6c3e9e0-fb24-4f17-97c2-6e06b2b43584';

-- Step 4: Delete all other households
DELETE FROM households
WHERE id != 'e6c3e9e0-fb24-4f17-97c2-6e06b2b43584';

-- Step 5: Verify cleanup
SELECT 'REMAINING HOUSEHOLDS:' as info;
SELECT id, name, invite_code FROM households;

SELECT 'REMAINING PROFILES:' as info;
SELECT id, full_name, role, age, household_id FROM profiles;

SELECT 'REMAINING HOUSEHOLD MEMBERS:' as info;
SELECT hm.household_id, h.name, p.full_name, p.role
FROM household_members hm
JOIN households h ON h.id = hm.household_id
JOIN profiles p ON p.id = hm.user_id;
