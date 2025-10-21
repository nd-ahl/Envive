# Onboarding Flow - Now Live! 🎉

Your new onboarding screens are now wired up and will show automatically!

## What Changed

### 1. Updated OnboardingManager
Added a new step in the flow: `hasCompletedFamilySetup`

**New Flow Order:**
1. Welcome Screen
2. Onboarding Questions
3. Role Confirmation
4. Household Selection
5. Sign In / Sign Up
6. **→ ADD PROFILES (NEW!)** ← Shows here (with age wheel!)
7. **→ LINK DEVICES (NEW!)** ← Then this
8. ~~Age Selection~~ ← REMOVED (age collected in step 6)
9. Permissions
10. Benefits
11. Main App

### 2. Updated EnviveNewApp.swift
Added the `OnboardingCoordinator` to show between sign-in and age selection.

## Testing the Flow

### Option 1: Reset Onboarding (Easiest)
1. Build and run the app
2. If you're already past onboarding, go to **Settings** tab
3. Scroll to "Debug & Testing"
4. Tap **Reset Onboarding**
5. App will close
6. Reopen the app
7. Go through the flow until you see the new screens!

### Option 2: Fresh Install
1. Delete the app from simulator
2. Build and run
3. Go through onboarding
4. After signing up → **Add Profiles screen appears!**
5. Then → **Link Devices screen!**

### Option 3: Manual Flag Reset
Run this in Xcode console while app is running:
```swift
UserDefaults.standard.set(false, forKey: "hasCompletedFamilySetup")
UserDefaults.standard.set(false, forKey: "hasCompletedSignIn")
```
Then restart the app.

## What You'll See

### Screen 1: Add Profiles
- Title: "Add Your Family"
- Subtitle: "Create profiles for everyone who will be doing tasks"
- Empty state with icon
- **Add Profile** button
- **Skip for Now** link
- **Save & Continue** button

**When you tap Add Profile:**
- Modal sheet slides up
- Photo picker at top
- Name field
- Birthday picker
- **Save Profile** button

**After adding profiles:**
- Cards appear with avatar, name, birthday
- Edit and delete buttons on each card
- Can add multiple children

### Screen 2: Link Devices
- Title: "Link Additional Devices"
- Household invite code displayed (6 digits)
- **Copy Code** button → Shows "Code copied!" message
- **Share** button → Opens system share sheet
- Network sharing toggle
- Info about how to use the code
- **Get Started** button
- "I'll set this up later" link

## How It Works

### Flow Triggered By
The family setup screens appear automatically when:
- User completes sign-in/sign-up
- `hasCompletedSignIn = true`
- `hasCompletedFamilySetup = false`

### Data Saved
When you complete the flow:
- Child profiles saved to Supabase `profiles` table
- Profile pictures uploaded to `avatars` storage bucket
- Household invite code already generated
- Flag `hasCompletedFamilySetup` set to `true`

### Can Be Skipped
- Users can tap "Skip for Now" on Add Profiles
- Or "I'll set this up later" on Link Devices
- Flow continues normally
- Profiles can be added later from settings

## Database Requirements

**Before testing, make sure you've run:**
1. ✅ `database/migrations/004_auto_create_profiles.sql` (Apple Sign In fix)
2. ✅ `database/migrations/005_add_profile_fields.sql` (Avatar & birthday fields)

**And set up storage:**
1. Create `avatars` bucket in Supabase Storage
2. Set to Public

## Debugging

### "Screens don't appear"
Check in debugger:
```swift
print(OnboardingManager.shared.hasCompletedSignIn) // Should be true
print(OnboardingManager.shared.hasCompletedFamilySetup) // Should be false
print(OnboardingManager.shared.shouldShowFamilySetup) // Should be true
```

### "Can't save profiles"
- Check database migrations ran
- Verify household was created during sign-up
- Check Supabase logs for errors

### "Avatar upload fails"
- Verify `avatars` bucket exists
- Check bucket permissions (public or RLS)
- Test internet connection

### "Code doesn't show"
Check:
```swift
print(HouseholdService.shared.currentHousehold?.inviteCode)
print(UserDefaults.standard.string(forKey: "householdCode"))
```

## Next Steps

After testing the onboarding:

1. **Test the full flow** from welcome to main app
2. **Add a child profile** with photo
3. **Copy/share the invite code**
4. **Use the code** to join household from another device (future feature)
5. **Load household members** in the parent dashboard
6. **Assign tasks** to children

## Files Modified

- ✅ `OnboardingManager.swift` - Added `hasCompletedFamilySetup` flag
- ✅ `EnviveNewApp.swift` - Added `OnboardingCoordinator` to flow
- ✅ `HouseholdService.swift` - Added `createChildProfile()` method
- ✅ `DatabaseModels.swift` - Added `avatar_url` and `birthday` fields

## Files Created

- ✅ `AddProfilesView.swift`
- ✅ `AddChildProfileSheet.swift`
- ✅ `LinkDevicesView.swift`
- ✅ `OnboardingCoordinator.swift`

Everything is ready to go! Just build and run to see your new onboarding flow! 🚀
