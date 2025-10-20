# Super Simple Supabase Setup Guide

Follow these exact steps - should take about 5 minutes!

## Step 1: Open Supabase Dashboard

1. Go to: https://supabase.com/dashboard
2. Log in to your account
3. You should see your project listed
4. Click on your project name

## Step 2: Open SQL Editor

1. On the left sidebar, find and click **"SQL Editor"** (it has a `</>` icon)
2. You'll see a text editor on the right side

## Step 3: Run Each SQL Command

**IMPORTANT**: Copy and paste each command ONE AT A TIME, then click "RUN" after each one.

---

### Command 1: Create Profiles Table

Copy this entire block and paste it into the SQL Editor:

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

**Then click the "RUN" button (bottom right)**

You should see: ✅ "Success. No rows returned"

---

### Command 2: Create Households Table

**Clear the SQL Editor**, then copy and paste this:

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

**Click "RUN"**

You should see: ✅ "Success. No rows returned"

---

### Command 3: Create Household Members Table

**Clear the SQL Editor**, then copy and paste this:

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

**Click "RUN"**

You should see: ✅ "Success. No rows returned"

---

### Command 4: Create Updated At Trigger

**Clear the SQL Editor**, then copy and paste this:

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

**Click "RUN"**

You should see: ✅ "Success. No rows returned"

---

## Step 4: Verify It Worked

**Clear the SQL Editor**, then copy and paste this:

```sql
-- Check that all tables were created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'households', 'household_members');
```

**Click "RUN"**

You should see a table with 3 rows:
- profiles
- households
- household_members

---

## ✅ You're Done!

If you see all 3 tables, your backend is ready!

## What You Just Created

- **profiles**: Stores user info (name, email, role, which household they're in)
- **households**: Stores household names and invite codes
- **household_members**: Links users to their households

## What Happens Now

When someone uses your app:

1. **Sign Up**: Creates a row in `profiles` table
2. **Create Household**: Creates a row in `households` with a 6-digit invite code
3. **Join Household**: Finds household by invite code, adds user to `household_members`

## Troubleshooting

**If you get an error like "table already exists":**
- The table was already created
- You can skip that command and move to the next one

**If you get an error like "permission denied":**
- Make sure you're logged into the correct Supabase project
- Make sure you're the owner/admin of the project

**If nothing happens when you click RUN:**
- Make sure you pasted the SQL into the editor
- Try refreshing the page

---

Need help? Just let me know which step you're stuck on!
