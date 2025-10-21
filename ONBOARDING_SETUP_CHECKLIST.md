# Onboarding Setup Checklist

Complete onboarding flow for adding family members and linking devices after sign-up.

## What Was Built

### 1. User Flow
After signing up with Apple or Email:
1. **Add Profiles Screen** - Create child profiles with photos, names, birthdays
2. **Link Devices Screen** - Share household invite code with family

### 2. New Views Created
- ✅ `AddProfilesView.swift` - Add family members
- ✅ `AddChildProfileSheet.swift` - Profile creation modal with photo picker
- ✅ `LinkDevicesView.swift` - Display & share household code
- ✅ `OnboardingCoordinator.swift` - Manages the flow

### 3. Database Updates
- ✅ Added `avatar_url` field to profiles
- ✅ Added `birthday` field to profiles
- ✅ Auto-profile creation trigger (from previous fix)

### 4. Services Updated
- ✅ `HouseholdService.createChildProfile()` - Creates child profiles
- ✅ `HouseholdService.uploadProfilePicture()` - Uploads to Supabase Storage

## Setup Steps (Do These Now)

### Step 1: Database Migrations ⚡
Run these SQL files in your **Supabase SQL Editor**:

1. ✅ Already run: `004_auto_create_profiles.sql`
2. 🔲 **Run now**: `005_add_profile_fields.sql`

```sql
-- Adds avatar_url and birthday columns
ALTER TABLE profiles ADD COLUMN avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN birthday DATE;
```

### Step 2: Supabase Storage Setup ⚡

**Option A: Manual Setup (Recommended)**
1. Go to Supabase Dashboard → **Storage**
2. Click **New Bucket**
3. Name: `avatars`
4. Set to **Public** ✓
5. Click **Create**

**Option B: With RLS Policies**
1. Create bucket manually (as above)
2. Run `database/setup_storage.sql` for fine-grained permissions

### Step 3: Test in Simulator ⚡

1. **Delete existing test user** (optional - for clean test):
   ```sql
   -- In Supabase SQL Editor
   DELETE FROM profiles WHERE email = 'your-test@email.com';
   DELETE FROM auth.users WHERE email = 'your-test@email.com';
   ```

2. **Build and run** the app
3. **Sign up** with a new account
4. **You should see** the Add Profiles screen automatically
5. **Add a child** and test the full flow

### Step 4: Wire Up to Your App ⚡

Add the `OnboardingCoordinator` to your navigation flow.

**Quick Integration Example:**

```swift
// In your root/main view
import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService.shared

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                // Your existing sign-in flow
                WelcomeView()
            } else if !hasCompletedOnboarding {
                // NEW: Show onboarding after signup
                OnboardingCoordinator {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
            } else {
                // Your existing main app
                EnviveMainView()
            }
        }
    }

    private var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}
```

See `ONBOARDING_INTEGRATION.md` for more detailed integration options.

## Quick Test

### Test the Add Profiles Screen
1. Sign up with a new account
2. Should see "Add Your Family" screen
3. Tap **Add Profile**
4. Fill in:
   - Name: "Test Child"
   - Birthday: (pick any date)
   - Photo: (optional)
5. Tap **Save Profile**
6. Profile card should appear
7. Tap **Save & Continue**

### Test the Link Devices Screen
1. Should see "Link Additional Devices"
2. Household code should display (6 digits)
3. Tap **Copy Code** → Should show "Code copied!"
4. Tap **Share** → System share sheet appears
5. Tap **Get Started** → Complete onboarding

## Features

### Add Profiles Screen
- ➕ Add multiple child profiles
- 📷 Upload profile pictures
- 🎂 Select age with scroll wheel (5-17 years)
- ✏️ Edit existing profiles
- 🗑️ Delete profiles
- ⏭️ Skip option
- ✨ Auto-closes modal on save

### Link Devices Screen
- 🔢 Display household invite code
- 📋 Copy to clipboard
- 📤 Share via system sheet
- 🔗 Network sharing toggle (future feature)
- ⏭️ "Set up later" option

### Profile Creation Modal
- 📸 Photo picker integration
- ✅ Name validation
- 🎯 Age scroll wheel (same as existing onboarding)
- 💾 Auto-closes on save (prevents duplicate saves)
- ✏️ Edit mode support

## Database Structure

### Profiles Table (Updated)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  role TEXT,  -- 'parent' or 'child'
  household_id UUID,
  avatar_url TEXT,     -- NEW
  birthday DATE,       -- NEW
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

### How Child Profiles Work
- Children are **profile entries** (not auth users)
- No email/password required
- Linked to household via `household_id`
- Parents manage all child profiles
- Profile pictures stored in Supabase Storage

## Household Invite Codes

Every household has a unique 6-digit code:
- Generated automatically on household creation
- Stored in `households.invite_code`
- Used to join households from other devices
- Shareable via copy/paste or system share sheet

**Where the code is stored:**
```swift
// In HouseholdService
householdService.currentHousehold?.inviteCode

// In UserDefaults (fallback)
UserDefaults.standard.string(forKey: "householdCode")
```

## Troubleshooting

### "Profile creation failed"
- ✓ Run migration `005_add_profile_fields.sql`
- ✓ Check RLS policies allow profile inserts
- ✓ Verify household_id exists

### "Avatar upload failed"
- ✓ Create `avatars` bucket in Supabase Storage
- ✓ Set bucket to Public
- ✓ Check internet connection

### "Invite code not showing"
- ✓ Verify household was created during sign-up
- ✓ Check `HouseholdService.currentHousehold` is set
- ✓ Look in UserDefaults for `householdCode`

### "Onboarding not showing"
- ✓ Wire up `OnboardingCoordinator` in your root view
- ✓ Check `hasCompletedOnboarding` logic
- ✓ Verify user is authenticated

## File Locations

```
EnviveNew/
├── Views/Onboarding/
│   ├── AddProfilesView.swift             ← NEW
│   ├── AddChildProfileSheet.swift        ← NEW
│   ├── LinkDevicesView.swift             ← NEW
│   └── OnboardingCoordinator.swift       ← NEW
├── Core/Models/
│   └── DatabaseModels.swift              ← UPDATED
├── Services/Household/
│   └── HouseholdService.swift            ← UPDATED
database/
├── migrations/
│   └── 005_add_profile_fields.sql        ← NEW
└── setup_storage.sql                     ← NEW
```

## Next Steps

Once onboarding is working:

1. **Load household members** on parent dashboard
2. **Display children** in child selector
3. **Assign tasks** to specific children
4. **Test joining** household with invite code
5. **Add "Manage Family"** screen to edit profiles later

## Documentation

- 📖 `ONBOARDING_INTEGRATION.md` - Detailed integration guide
- 📖 `APPLE_SIGNIN_FIX.md` - Apple Sign In setup (already done)
- 📖 This file - Quick setup checklist

## Status

- ✅ Views created
- ✅ Services updated
- ✅ Database schema defined
- 🔲 Run database migrations
- 🔲 Set up storage bucket
- 🔲 Wire up to app navigation
- 🔲 Test complete flow

## Questions?

If something isn't working:
1. Check the Troubleshooting section
2. Review `ONBOARDING_INTEGRATION.md`
3. Check Supabase logs
4. Verify all migrations ran successfully
