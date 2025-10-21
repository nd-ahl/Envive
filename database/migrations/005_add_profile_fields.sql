-- ============================================
-- ADD PROFILE FIELDS FOR ONBOARDING
-- Adds avatar_url and age fields to profiles
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
