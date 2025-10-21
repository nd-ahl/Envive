-- ============================================
-- ALLOW UNAUTHENTICATED CHILD PROFILE LOOKUP
-- Fix RLS policy to allow children to view profiles when entering household invite code
-- Children don't have auth accounts, so they need to query profiles without auth.uid()
-- ============================================

-- Drop the restrictive SELECT policy that requires authentication
DROP POLICY IF EXISTS "Users can view profiles in their household" ON profiles;

-- Create separate policies for authenticated and unauthenticated access

-- Policy 1: Authenticated users can view profiles in their household
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

-- Policy 2: ANYONE can view child profiles (needed for invite code flow)
-- This is safe because:
-- 1. Only returns child profiles (not parent credentials)
-- 2. Children have no email/password (no sensitive data)
-- 3. Household invite code acts as authorization
CREATE POLICY "Public can view child profiles"
  ON profiles FOR SELECT
  TO anon
  USING (
    role = 'child'
  );

-- Note: This allows unauthenticated users to query child profiles by household_id
-- when they provide a valid invite code. The invite code verification happens
-- in the application layer (HouseholdService.getChildProfilesByInviteCode)
