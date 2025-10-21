-- ============================================
-- VERIFICATION SCRIPT
-- Run this in Supabase SQL Editor to check everything
-- ============================================

-- 1. Check if the trigger function exists
SELECT
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'handle_new_user'
  AND n.nspname = 'public';

-- 2. Check if the trigger is active
SELECT
    tgname as trigger_name,
    tgenabled as enabled,
    tgtype as trigger_type
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

-- 3. Check RLS policies on profiles table
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- 4. Check recent auth users (last 5)
SELECT
    id,
    email,
    created_at,
    raw_user_meta_data->>'full_name' as metadata_name,
    raw_user_meta_data->>'role' as metadata_role,
    raw_app_meta_data
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 5. Check recent profiles (last 5)
SELECT
    id,
    email,
    full_name,
    role,
    household_id,
    created_at,
    updated_at
FROM profiles
ORDER BY created_at DESC
LIMIT 5;

-- 6. Check if auth users have matching profiles
SELECT
    u.id,
    u.email as auth_email,
    u.created_at as auth_created,
    p.email as profile_email,
    p.full_name,
    p.role,
    p.created_at as profile_created,
    CASE
        WHEN p.id IS NULL THEN '❌ NO PROFILE'
        ELSE '✅ HAS PROFILE'
    END as status
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
ORDER BY u.created_at DESC
LIMIT 10;
