-- ============================================
-- ALLOW PARENTS TO CREATE CHILD PROFILES
-- Fix RLS policy to allow parents to create child profiles in their household
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

CREATE POLICY "Users can view profiles in their household"
  ON profiles FOR SELECT
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
