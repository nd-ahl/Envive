-- ============================================
-- DIAGNOSTIC SCRIPT: Check Child Profile Setup
-- Run this in Supabase SQL Editor to diagnose issues
-- ============================================

-- Step 1: Check if RLS policies exist
SELECT
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Step 2: Check all households
SELECT
    id,
    name,
    invite_code,
    created_by,
    created_at
FROM households
ORDER BY created_at DESC
LIMIT 10;

-- Step 3: Check all profiles (parent and child)
SELECT
    id,
    email,
    full_name,
    role,
    household_id,
    age,
    created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 20;

-- Step 4: Check household_members table
SELECT
    hm.household_id,
    h.name as household_name,
    h.invite_code,
    hm.user_id,
    p.full_name,
    p.role,
    hm.joined_at
FROM household_members hm
JOIN households h ON h.id = hm.household_id
JOIN profiles p ON p.id = hm.user_id
ORDER BY hm.joined_at DESC
LIMIT 20;

-- Step 5: Check if you can query child profiles WITHOUT auth (simulating the app)
-- This should return results if RLS is configured correctly
SET ROLE anon; -- Simulate unauthenticated user
SELECT
    id,
    full_name,
    role,
    household_id,
    age
FROM profiles
WHERE role = 'child'
LIMIT 10;
RESET ROLE;

-- Step 6: Find child profiles for a specific invite code
-- REPLACE '123456' with your actual invite code
DO $$
DECLARE
    test_code TEXT := '123456'; -- CHANGE THIS TO YOUR ACTUAL CODE
    household_rec RECORD;
BEGIN
    -- Find household
    SELECT * INTO household_rec
    FROM households
    WHERE invite_code = test_code;

    IF household_rec.id IS NULL THEN
        RAISE NOTICE 'ERROR: No household found with invite code: %', test_code;
    ELSE
        RAISE NOTICE 'SUCCESS: Found household: % (ID: %)', household_rec.name, household_rec.id;

        -- Check for child profiles
        RAISE NOTICE 'Child profiles in this household:';
        FOR household_rec IN
            SELECT full_name, age, id
            FROM profiles
            WHERE household_id = household_rec.id
            AND role = 'child'
        LOOP
            RAISE NOTICE '  - % (age %, ID: %)', household_rec.full_name, household_rec.age, household_rec.id;
        END LOOP;
    END IF;
END $$;
