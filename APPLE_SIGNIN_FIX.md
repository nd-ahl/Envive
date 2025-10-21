# Apple Sign In Profile Creation Fix

## The Problem
When users signed up with Apple Sign In, the app showed "Database error saving new user". This happened because:

1. The Row Level Security (RLS) policy required `auth.uid() = id` for profile inserts
2. The app tried to manually create profiles AFTER authentication
3. This created a timing/permission issue where the profile couldn't be inserted

## The Solution
Instead of manually creating profiles in the app, we now use a **database trigger** that automatically creates profiles when new users sign up. This is:
- ✅ More secure (uses `SECURITY DEFINER` to bypass RLS only for this specific operation)
- ✅ More reliable (no timing issues)
- ✅ Simpler code (no manual profile creation needed)

## Files Changed

### 1. Database Migration (NEW)
**File:** `database/migrations/004_auto_create_profiles.sql`
- Creates a trigger function that auto-creates profiles
- Sets up secure RLS policies
- Runs automatically when new auth users are created

### 2. Swift Code (UPDATED)
**File:** `EnviveNew/Services/Auth/AuthenticationService.swift`
- Removed manual profile creation logic from `signInWithApple()`
- Removed manual profile creation logic from `signUp()`
- Added small delay to wait for database trigger to complete
- Simplified the code significantly

## How to Apply the Fix

### Step 1: Run the Database Migration
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Copy and paste the contents of `database/migrations/004_auto_create_profiles.sql`
4. Click **Run**

### Step 2: Test Apple Sign In
1. Delete any test users from your database (optional, for clean testing)
2. Build and run the app
3. Try signing in with Apple
4. The profile should be created automatically! ✨

## What Happens Now

### When a user signs up with Apple:
1. Supabase creates an auth user with the Apple ID token
2. **Database trigger automatically creates a profile** (new!)
3. App loads the profile (0.5 second delay to ensure trigger completes)
4. User is authenticated and ready to go

### Security
- RLS policies are secure: users can only read/update their own profiles
- Only the database trigger can bypass RLS (using `SECURITY DEFINER`)
- No overly permissive policies like `WITH CHECK (true)`

## Troubleshooting

If you still see errors after applying the fix:

1. **Check the trigger was created:**
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
   ```

2. **Check the function exists:**
   ```sql
   SELECT * FROM pg_proc WHERE proname = 'handle_new_user';
   ```

3. **Manually test the trigger:**
   ```sql
   -- This should create both auth user AND profile
   -- (Don't actually run this, just for reference)
   ```

4. **Check profile was created:**
   ```sql
   SELECT * FROM profiles WHERE email = 'your-test-email@example.com';
   ```

## Files You Can Delete (After Applying Fix)

Once the migration is run and everything works:
- `fix_profile_creation.sql` (old insecure fix)
