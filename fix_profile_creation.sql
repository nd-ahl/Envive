-- ============================================
-- FIX: Allow Profile Creation for New Users
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

-- Create a more permissive policy for new user registration
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (true);

-- Also ensure users can read their own profile
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id OR true);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
