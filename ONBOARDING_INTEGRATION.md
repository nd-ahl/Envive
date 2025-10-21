## Onboarding Flow Integration Guide

This guide shows how to integrate the new onboarding flow into your app.

## Overview

After a user creates an account (via Apple Sign In or Email), they will go through:
1. **Add Profiles Screen** - Create child profiles with names, birthdays, and photos
2. **Link Devices Screen** - View household invite code and share with family

## Files Created

### Views
- `AddProfilesView.swift` - Main screen for adding family members
- `AddChildProfileSheet.swift` - Modal for creating/editing a child profile
- `LinkDevicesView.swift` - Screen showing household invite code
- `OnboardingCoordinator.swift` - Manages the onboarding flow

### Models & Services
- `DatabaseModels.swift` - Updated with `avatar_url` and `birthday` fields
- `HouseholdService.swift` - Added `createChildProfile()` and `uploadProfilePicture()` methods

### Database Migrations
- `005_add_profile_fields.sql` - Adds `avatar_url` and `birthday` columns to profiles table

## Integration Steps

### Step 1: Run Database Migrations

Run these migrations in your Supabase SQL Editor:

1. `database/migrations/004_auto_create_profiles.sql` (if not already run)
2. `database/migrations/005_add_profile_fields.sql`

### Step 2: Set Up Storage Bucket

In Supabase Dashboard:
1. Go to **Storage**
2. Create a new bucket named `avatars`
3. Set it to **Public** (or configure RLS policies)

### Step 3: Update Your Root Navigation

Option A: Simple Integration (Recommended)
```swift
// In your main ContentView or root navigation view
struct RootView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                // Your sign-in flow
                WelcomeView()
            } else if !hasCompletedOnboarding {
                // NEW: Onboarding flow
                OnboardingCoordinator {
                    // Onboarding complete, refresh UI
                }
            } else {
                // Your main app
                MainAppView()
            }
        }
    }

    private var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}
```

Option B: Navigation Integration
```swift
// In HouseholdSelectionView or wherever you handle post-signup
NavigationLink(
    destination: OnboardingCoordinator {
        // Navigate to main app
    },
    isActive: $showOnboarding
) {
    EmptyView()
}
```

### Step 4: Update SignInView (Optional)

If you want to automatically show onboarding after signup, modify `SignInView.swift`:

```swift
// In handleAppleSignIn() after creating household
if isCreatingHousehold {
    // ... existing household creation code ...

    await MainActor.run {
        isLoading = false
        // Instead of onComplete(), navigate to onboarding
        showOnboarding = true
    }
}
```

## Usage Flow

### For New Users (Creating Household)
1. User signs up with Apple or Email
2. Household is automatically created
3. → **AddProfilesView** appears
   - Can add multiple child profiles
   - Each profile has: name, birthday, optional photo
   - Can skip this step
4. → **LinkDevicesView** appears
   - Shows household invite code (6 digits)
   - Can copy or share the code
   - Optional network sharing toggle
5. → Main app

### For Existing Users (Joining Household)
1. User signs in
2. Checks if household exists
3. If no household → Join household flow
4. If household exists → Skip to main app

## Child Profiles

Child profiles are created as:
- **Profile entries** (not full auth users)
- Linked to the parent's household via `household_id`
- Added to `household_members` table
- Have role = "child"

### Creating a Child Profile

```swift
let childId = try await householdService.createChildProfile(
    name: "Emma",
    birthday: Date(),
    householdId: household.id,
    createdBy: parentProfile.id,
    avatarUrl: nil  // Optional
)
```

### Uploading Profile Pictures

```swift
if let imageData = image.jpegData(compressionQuality: 0.8) {
    let avatarUrl = try await householdService.uploadProfilePicture(
        userId: childId,
        imageData: imageData
    )
}
```

## Household Invite Codes

The household invite code is:
- **6 digits** (e.g., "123456")
- Automatically generated when household is created
- Stored in `households.invite_code`
- Used to join existing households

### Accessing the Code

```swift
// From HouseholdService
let household = householdService.currentHousehold
let code = household?.inviteCode

// From UserDefaults (fallback)
let code = UserDefaults.standard.string(forKey: "householdCode")
```

### Sharing the Code

LinkDevicesView provides:
- **Copy button** - Copies code to clipboard
- **Share button** - Opens system share sheet with formatted message

## Testing the Flow

1. **Delete test user** from Supabase (optional, for clean testing)
2. **Run the app**
3. **Sign up** with Apple or Email
4. **Add a child profile**:
   - Name: "Test Child"
   - Birthday: Pick a date
   - Photo: Optional
5. **Save profile** - Should see it in the list
6. **Continue** to Link Devices screen
7. **Verify invite code** appears
8. **Copy or share** the code
9. **Complete onboarding**

## Troubleshooting

### "Profile creation failed"
- Check database migrations are run
- Verify RLS policies allow inserts
- Check Supabase logs

### "Avatar upload failed"
- Verify `avatars` storage bucket exists
- Check bucket is public or has proper RLS
- Verify image data is valid

### "Household code not showing"
- Check household was created in `SignInView`
- Verify `householdService.currentHousehold` is set
- Check UserDefaults has `householdCode` key

### Child profiles not appearing
- Verify `household_id` matches parent's household
- Check `household_members` table has entries
- Refresh `householdMembers` in `HouseholdService`

## Next Steps

After onboarding is complete:
- Load all household members
- Display them in parent/child dashboards
- Allow task assignment to children
- Enable device linking with invite codes

## Notes

- Child profiles are NOT auth users (they don't have login credentials)
- Parents manage all child profiles
- All data is properly linked via `household_id`
- Invite codes are unique per household
- Onboarding can be skipped (profiles can be added later)
