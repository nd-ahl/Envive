# Parent Name Entry Feature ✅

Added a name entry step during onboarding so parents can set their display name.

## What Was Added

### New Onboarding Step
**Screen:** `ParentNameEntryView.swift`
- Beautiful gradient background (matches existing onboarding)
- Text field for parent to enter their name
- Pre-fills from Apple/Email sign-in if available
- Validates name is not empty
- Saves to UserDefaults and Supabase

### Updated Onboarding Flow

**New Flow Order:**
1. Welcome Screen
2. Onboarding Questions
3. Role Confirmation
4. Household Selection
5. Sign In / Sign Up
6. **→ ENTER YOUR NAME (NEW!)** ← Shows here
7. Add Profiles (children)
8. Link Devices
9. Permissions
10. Benefits
11. Main App

### Settings Integration
The parent's name now appears in Settings and can be edited:
- Displays in Settings → Profile section
- Tap to edit (shows alert dialog)
- Saves to both UserDefaults and Supabase
- Updates in real-time

## How It Works

### During Onboarding
1. Parent signs up with Apple or Email
2. **Name Entry Screen** appears
   - Pre-filled if name available from sign-up
   - Otherwise shows empty field
3. Parent enters their name
4. Taps **Continue**
5. Name saved to:
   - UserDefaults (`parentName`)
   - Supabase `profiles.full_name`

### In Settings
1. Go to Settings tab (parent mode)
2. See "Name" row in Profile section
3. Current name displayed (or "Add name" if not set)
4. Tap the row
5. Edit name in alert dialog
6. Tap **Save**
7. Updates UserDefaults and Supabase

## Files Created

**New:**
- ✅ `Views/Onboarding/ParentNameEntryView.swift` - Name entry screen

**Modified:**
- ✅ `Managers/OnboardingManager.swift` - Added `hasCompletedNameEntry` flag
- ✅ `EnviveNewApp.swift` - Wired up name entry step
- ✅ `Views/Shared/RootNavigationView.swift` - Display & edit name in settings

## Data Storage

### UserDefaults
```swift
UserDefaults.standard.string(forKey: "parentName")
```

### Supabase
```sql
UPDATE profiles
SET full_name = 'Parent Name'
WHERE id = user_id;
```

### Accessed Via
```swift
// In code
OnboardingManager.shared.parentName

// In views
@ObservedObject private var onboardingManager = OnboardingManager.shared
Text(onboardingManager.parentName ?? "")
```

## UI Design

### Name Entry Screen
- 👋 Wave emoji icon
- **Title:** "What's your name?"
- **Subtitle:** "This helps personalize your family's experience"
- Text field with placeholder
- Helper text: "This will be shown to your family"
- Continue button (disabled until name entered)
- Smooth animations on appear

### Settings Display
```
Profile
├─ [Photo]
├─ Name          John Smith  >
└─ Role          Parent
```

Tap "Name" row → Alert dialog opens:
```
Edit Name
Enter your name

[         John Smith         ]

[Cancel]  [Save]
```

## Testing

### Test During Onboarding
1. Reset onboarding (Settings → Debug → Reset Onboarding)
2. Go through flow
3. After sign-up → **Name entry screen appears**
4. Enter "Test Parent"
5. Tap Continue
6. Proceeds to Add Profiles screen

### Test in Settings
1. Open app in parent mode
2. Go to Settings tab
3. See name in Profile section
4. Tap name row
5. Edit to "New Name"
6. Tap Save
7. Name updates immediately

### Verify Supabase
```sql
-- Check the name was saved
SELECT id, email, full_name
FROM profiles
WHERE email = 'your-test@email.com';
```

## Edge Cases Handled

### No Name from Sign-Up
- Field is empty
- Parent must enter name
- Cannot continue without name

### Name Already Exists
- Pre-fills from sign-up
- Parent can edit or keep it
- Updates on save

### Settings Edit
- Empty name → shows "Add name"
- Can always edit later
- Saves to both local and database

## Integration Points

### Used Throughout App
The parent name can be used for:
- Personalized greetings
- Task notifications ("Mom assigned you a task")
- Profile displays
- Household member lists
- Share messages

### Future Enhancements
- Display parent name in child app
- Use in task assignments ("Complete [task] for [parent name]")
- Show in household member list
- Personalize notifications

## Benefits

✅ **Better Personalization** - Family sees who created tasks
✅ **Clear Identity** - No confusion about "the parent"
✅ **Consistent Experience** - Name throughout the app
✅ **Editable** - Can update anytime in settings
✅ **Synced** - Saved to database for multi-device

## Notes

- Name is required during onboarding
- Stored in both UserDefaults (cache) and Supabase (source of truth)
- Can be edited anytime in settings
- Updates are immediate
- No duplicate names validation (same household can have multiple "Mom")

Everything is ready! Build and test the new name entry flow! 🎉
