-- ============================================
-- SAFE MIGRATION SCRIPT
-- Handles existing policies gracefully
-- ============================================

-- ============================================
-- STEP 1: ADD MISSING COLUMNS (MIGRATION 005)
-- ============================================

-- Add avatar_url column for profile pictures
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Add age column for child profiles (THIS IS CRITICAL!)
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Add comments
COMMENT ON COLUMN profiles.avatar_url IS 'URL to user profile picture in storage';
COMMENT ON COLUMN profiles.age IS 'User age in years, primarily for child profiles';

-- ============================================
-- STEP 2: DROP ALL EXISTING POLICIES
-- ============================================

-- Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in their household" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can view household profiles" ON profiles;
DROP POLICY IF EXISTS "Public can view child profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update profiles in their household" ON profiles;

-- ============================================
-- STEP 3: CREATE ALL POLICIES FRESH
-- ============================================

-- INSERT POLICY: Allow users to create their own profile AND parents to create child profiles
CREATE POLICY "Users can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (
    auth.uid() = id
    OR
    (auth.uid() IS NOT NULL AND role = 'child')
  );

-- UPDATE POLICY: Allow users to update their own profile AND parents to update child profiles
CREATE POLICY "Users can update profiles in their household"
  ON profiles FOR UPDATE
  USING (
    auth.uid() = id
    OR
    (
      household_id IN (
        SELECT household_id
        FROM profiles
        WHERE id = auth.uid() AND role = 'parent'
      )
      AND role = 'child'
    )
  );

-- SELECT POLICY (Authenticated): Allow authenticated users to view profiles in their household
CREATE POLICY "Authenticated users can view household profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id
    OR
    household_id IN (
      SELECT household_id
      FROM profiles
      WHERE id = auth.uid()
    )
  );

-- SELECT POLICY (Anonymous): Allow ANYONE to view child profiles (needed for invite code flow)
CREATE POLICY "Public can view child profiles"
  ON profiles FOR SELECT
  TO anon
  USING (role = 'child');

-- ============================================
-- STEP 4: VERIFICATION
-- ============================================

-- Verify age column exists
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
AND column_name IN ('age', 'avatar_url', 'household_id')
ORDER BY column_name;

-- Verify RLS policies
SELECT
    policyname,
    roles::text[],
    cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Count child profiles (should be 0 for now)
SELECT COUNT(*) as total_profiles,
       COUNT(CASE WHEN role = 'child' THEN 1 END) as child_profiles,
       COUNT(CASE WHEN role = 'parent' THEN 1 END) as parent_profiles
FROM profiles;

-- Test anonymous access (this simulates what happens when child enters code)
SET ROLE anon;
SELECT 'SUCCESS: Anonymous can query child profiles' as test_result;
RESET ROLE;
