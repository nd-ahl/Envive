# Supabase Backend Setup Guide

This guide will walk you through setting up your Supabase database for the Envive app.

## Prerequisites

- Supabase account (you already have this!)
- Project URL: `https://vevcxsjcqwlmmlchfymn.supabase.co`

## Step 1: Enable Authentication

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/vevcxsjcqwlmmlchfymn
2. Navigate to **Authentication** > **Providers**
3. Enable **Email** provider (it should already be enabled)
4. Enable **Apple** provider:
   - You'll need an Apple Developer account
   - Create a Service ID in your Apple Developer Console
   - Add your Service ID and Key to Supabase
   - **Redirect URL**: `YOUR_APP_BUNDLE_ID://supabase/callback`

## Step 2: Create Database Tables

Go to **SQL Editor** in your Supabase dashboard and run these commands **one at a time**:

### 2.1 Create Profiles Table

```sql
-- Create profiles table (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('parent', 'child')),
  household_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create index for household_id lookups
CREATE INDEX idx_profiles_household_id ON profiles(household_id);
```

### 2.2 Create Households Table

```sql
-- Create households table
CREATE TABLE households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  invite_code TEXT NOT NULL UNIQUE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE households ENABLE ROW LEVEL SECURITY;

-- Allow users to read households they're part of
CREATE POLICY "Users can view their household"
  ON households FOR SELECT
  USING (
    id IN (
      SELECT household_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Allow parents to create households
CREATE POLICY "Parents can create households"
  ON households FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Create index for invite code lookups
CREATE INDEX idx_households_invite_code ON households(invite_code);
```

### 2.3 Create Household Members Table

```sql
-- Create household_members junction table
CREATE TABLE household_members (
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('parent', 'child')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (household_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;

-- Allow users to view members of their household
CREATE POLICY "Users can view their household members"
  ON household_members FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Allow inserting household members
CREATE POLICY "Can add household members"
  ON household_members FOR INSERT
  WITH CHECK (
    household_id IN (
      SELECT household_id FROM profiles WHERE id = auth.uid()
    )
    OR
    user_id = auth.uid()
  );

-- Create indexes
CREATE INDEX idx_household_members_household ON household_members(household_id);
CREATE INDEX idx_household_members_user ON household_members(user_id);
```

### 2.4 Create Updated At Trigger

```sql
-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to profiles table
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add trigger to households table
CREATE TRIGGER update_households_updated_at
  BEFORE UPDATE ON households
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Step 3: Enable Realtime (Optional)

If you want real-time updates when household data changes:

1. Go to **Database** > **Replication**
2. Enable replication for these tables:
   - `profiles`
   - `households`
   - `household_members`

## Step 4: Test Your Setup

You can test your setup by running this query in the SQL Editor:

```sql
-- Check that all tables were created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'households', 'household_members');
```

You should see all three tables listed.

## Step 5: Verify Policies

Run this to check Row Level Security is enabled:

```sql
-- Verify RLS is enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'households', 'household_members');
```

All tables should show `rowsecurity = true`.

## What Happens Now?

With this setup complete, your app will:

1. **Sign Up Flow**:
   - User signs up with email/password or Apple
   - Profile is automatically created in `profiles` table
   - If creating a household, a new row is added to `households` with a 6-digit invite code
   - User is added to `household_members` table

2. **Join Household Flow**:
   - User enters 6-digit invite code
   - App finds matching household in `households` table
   - User is added to `household_members` table
   - User's `household_id` in `profiles` is updated

3. **Security**:
   - Row Level Security ensures users can only see their own household data
   - Parents can create households
   - Anyone with an invite code can join a household

## Troubleshooting

### Error: "permission denied for table X"
- Make sure Row Level Security policies are created
- Check that you're authenticated when testing

### Error: "duplicate key value violates unique constraint"
- This usually means the invite code already exists (very rare with 6-digit codes)
- Or you're trying to create a duplicate user/household member

### Can't see data after creating it
- Check Row Level Security policies
- Make sure you're querying as the authenticated user
- Use the SQL Editor with "Enable RLS" toggle OFF for debugging

## Next Steps

After completing this setup:

1. Test the sign-up flow in your app
2. Test creating a household
3. Test joining a household with an invite code
4. Check the Supabase dashboard to see data appearing in your tables

## Future Enhancements

You may want to add these tables later:

- `tasks` - Store task assignments
- `xp_transactions` - Track XP history
- `app_restrictions` - Store screen time settings
- `rewards` - Store reward redemptions

Each new table will need its own Row Level Security policies!
