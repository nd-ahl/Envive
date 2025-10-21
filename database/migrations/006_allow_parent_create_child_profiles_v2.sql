-- ============================================
-- ALLOW PARENTS TO CREATE CHILD PROFILES (v2 - Idempotent)
-- Fix RLS policy to allow parents to create child profiles in their household
-- ============================================

-- Drop ALL existing policies (both old and new names)
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert profiles" ON profiles;

DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in their household" ON profiles;

DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update profiles in their household" ON profiles;

-- Now create the new policies fresh
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
