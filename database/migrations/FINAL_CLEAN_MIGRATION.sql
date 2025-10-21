-- Add missing columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS age INTEGER;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in their household" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can view household profiles" ON profiles;
DROP POLICY IF EXISTS "Public can view child profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update profiles in their household" ON profiles;

-- INSERT policy
CREATE POLICY "Users can insert profiles"
ON profiles FOR INSERT
WITH CHECK (
  auth.uid() = id OR (auth.uid() IS NOT NULL AND role = 'child')
);

-- UPDATE policy
CREATE POLICY "Users can update profiles in their household"
ON profiles FOR UPDATE
USING (
  auth.uid() = id OR (
    household_id IN (SELECT household_id FROM profiles WHERE id = auth.uid() AND role = 'parent') AND role = 'child'
  )
);

-- SELECT policy for authenticated users
CREATE POLICY "Authenticated users can view household profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR household_id IN (SELECT household_id FROM profiles WHERE id = auth.uid())
);

-- SELECT policy for anonymous users (this is the key one!)
CREATE POLICY "Public can view child profiles"
ON profiles FOR SELECT
TO anon
USING (role = 'child');

-- Verify age column exists
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'profiles' AND column_name IN ('age', 'avatar_url');

-- Verify policies
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'profiles' ORDER BY policyname;

-- Count profiles
SELECT COUNT(*) as total, COUNT(CASE WHEN role = 'child' THEN 1 END) as children FROM profiles;
