-- ============================================
-- COMBINED MIGRATIONS: 005, 006, 007
-- Run this entire script in Supabase SQL Editor
-- ============================================

-- ============================================
-- MIGRATION 005: ADD PROFILE FIELDS
-- ============================================

-- Add avatar_url column for profile pictures
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Add age column for child profiles (integer, not date)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Add comment for documentation
COMMENT ON COLUMN profiles.avatar_url IS 'URL to user profile picture in storage';
COMMENT ON COLUMN profiles.age IS 'User age in years, primarily for child profiles';

-- ============================================
-- MIGRATION 006: ALLOW PARENT CREATE CHILD PROFILES
-- ============================================

-- Drop the restrictive insert policy
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

-- Create a new policy that allows:
-- 1. Users to insert their own profile (auth account creation)
-- 2. Parents to insert child profiles (no auth account)
CREATE POLICY "Users can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (
    -- Allow users to create their own profile (auth.uid matches profile id)
    auth.uid() = id
    OR
    -- Allow authenticated users to create child profiles (id doesn't match auth.uid)
    -- Child profiles have no corresponding auth.users entry, so they have a different ID
    (auth.uid() IS NOT NULL AND role = 'child')
  );

-- Allow parents to view child profiles in their household
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;

-- Temporarily drop this if it exists from migration 007
DROP POLICY IF EXISTS "Users can view profiles in their household" ON profiles;

-- Allow parents to update child profiles in their household
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

CREATE POLICY "Users can update profiles in their household"
  ON profiles FOR UPDATE
  USING (
    -- Users can update their own profile
    auth.uid() = id
    OR
    -- Parents can update child profiles in their household
    (
      household_id IN (
        SELECT household_id
        FROM profiles
        WHERE id = auth.uid() AND role = 'parent'
      )
      AND role = 'child'
    )
  );

-- ============================================
-- MIGRATION 007: ALLOW UNAUTHENTICATED CHILD PROFILE LOOKUP
-- ============================================

-- Create policy for authenticated users
CREATE POLICY "Authenticated users can view household profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    -- Users can view their own profile
    auth.uid() = id
    OR
    -- Users can view profiles in their household
    household_id IN (
      SELECT household_id
      FROM profiles
      WHERE id = auth.uid()
    )
  );

-- CREATE THIS POLICY - this is what fixes child profile lookup!
CREATE POLICY "Public can view child profiles"
  ON profiles FOR SELECT
  TO anon
  USING (role = 'child');

-- ============================================
-- VERIFICATION
-- ============================================

-- Test if anonymous users can see child profiles
SET ROLE anon;
SELECT COUNT(*) as child_profile_count FROM profiles WHERE role = 'child';
RESET ROLE;

-- Show all RLS policies on profiles table
SELECT
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;
