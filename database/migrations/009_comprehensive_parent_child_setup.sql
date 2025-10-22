-- ============================================
-- COMPREHENSIVE PARENT-CHILD SETUP & VERIFICATION
-- This migration ensures all triggers, policies, and constraints
-- are properly configured for parent-child linking
-- ============================================

-- STEP 1: Ensure profiles table has all necessary fields
-- ============================================
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS age INT,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Ensure household_id foreign key exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'profiles_household_id_fkey'
  ) THEN
    ALTER TABLE profiles
      ADD CONSTRAINT profiles_household_id_fkey
      FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE SET NULL;
  END IF;
END $$;


-- STEP 2: Verify and recreate handle_new_user trigger function
-- ============================================
-- This trigger automatically creates a profile when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insert a new profile for the user
  -- Extract metadata from auth.users
  INSERT INTO public.profiles (id, email, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    ),
    COALESCE(NEW.raw_user_meta_data->>'role', 'parent'),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- STEP 3: Ensure RLS policies support parent-child linking
-- ============================================

-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "Users can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in their household" ON profiles;
DROP POLICY IF EXISTS "Users can update profiles in their household" ON profiles;
DROP POLICY IF EXISTS "Users can delete profiles in their household" ON profiles;

-- INSERT: Allow users to create their own profile AND parents to create child profiles
CREATE POLICY "Users can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (
    -- Allow authenticated users to create their own profile
    auth.uid() = id
    OR
    -- Allow authenticated users to create child profiles (no auth.uid match)
    -- This is crucial for parent-created child accounts
    (auth.uid() IS NOT NULL AND role = 'child')
  );

-- SELECT: Allow users to view their profile and household members
CREATE POLICY "Users can view profiles in their household"
  ON profiles FOR SELECT
  USING (
    -- View own profile
    auth.uid() = id
    OR
    -- View profiles in same household
    household_id IN (
      SELECT household_id
      FROM profiles
      WHERE id = auth.uid() AND household_id IS NOT NULL
    )
  );

-- UPDATE: Allow users to update their profile and parents to update child profiles
CREATE POLICY "Users can update profiles in their household"
  ON profiles FOR UPDATE
  USING (
    -- Update own profile
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

-- DELETE: Only allow parents to delete child profiles in their household
CREATE POLICY "Users can delete profiles in their household"
  ON profiles FOR DELETE
  USING (
    -- Parents can delete child profiles in their household
    household_id IN (
      SELECT household_id
      FROM profiles
      WHERE id = auth.uid() AND role = 'parent'
    )
    AND role = 'child'
  );


-- STEP 4: Ensure household_members policies support child profiles
-- ============================================

DROP POLICY IF EXISTS "Can add household members" ON household_members;
DROP POLICY IF EXISTS "Can remove household members" ON household_members;

-- Allow adding members (both self-joining and parent-adding children)
CREATE POLICY "Can add household members"
  ON household_members FOR INSERT
  WITH CHECK (
    -- Allow users to join a household themselves
    user_id = auth.uid()
    OR
    -- Allow parents to add members to their household
    household_id IN (
      SELECT household_id FROM profiles WHERE id = auth.uid() AND role = 'parent'
    )
  );

-- Allow parents to remove members from their household
CREATE POLICY "Can remove household members"
  ON household_members FOR DELETE
  USING (
    -- Users can leave their own household
    user_id = auth.uid()
    OR
    -- Parents can remove members from their household
    household_id IN (
      SELECT household_id FROM profiles WHERE id = auth.uid() AND role = 'parent'
    )
  );


-- STEP 5: Create helper function to get household data
-- ============================================

-- Function to get all household members including children
CREATE OR REPLACE FUNCTION get_household_members(p_household_id UUID)
RETURNS TABLE (
  id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  household_id UUID,
  age INT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.household_id,
    p.age,
    p.avatar_url,
    p.created_at,
    p.updated_at
  FROM profiles p
  WHERE p.household_id = p_household_id
  ORDER BY
    CASE WHEN p.role = 'parent' THEN 0 ELSE 1 END,
    p.created_at;
END;
$$ LANGUAGE plpgsql;


-- STEP 6: Create indexes for performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_profiles_household_role
  ON profiles(household_id, role);

CREATE INDEX IF NOT EXISTS idx_profiles_role
  ON profiles(role);

CREATE INDEX IF NOT EXISTS idx_household_members_role
  ON household_members(household_id, role);


-- STEP 7: Grant necessary permissions
-- ============================================

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;


-- ============================================
-- VERIFICATION QUERIES (run these after migration)
-- ============================================

-- Check that trigger exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
  ) THEN
    RAISE WARNING '❌ Trigger on_auth_user_created does not exist!';
  ELSE
    RAISE NOTICE '✅ Trigger on_auth_user_created exists';
  END IF;
END $$;

-- Check that RLS is enabled
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename = 'profiles'
    AND rowsecurity = true
  ) THEN
    RAISE WARNING '❌ RLS is not enabled on profiles table!';
  ELSE
    RAISE NOTICE '✅ RLS is enabled on profiles table';
  END IF;
END $$;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 009 completed successfully!';
  RAISE NOTICE '📝 Parent-child linking is now fully configured';
  RAISE NOTICE '🔐 RLS policies allow parents to create/manage child profiles';
  RAISE NOTICE '🔄 Auto-profile creation trigger is active';
END $$;
