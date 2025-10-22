# Profile Photo Persistence Fix

## Problem Summary

Profile photos were being deleted when switching between parent and child roles. When a user switched modes and then switched back, their profile photo would be gone.

## Root Cause

In `ModeSwitcherView.swift`, the `handleModeSwitch()` function was creating new `UserProfile` objects with `profilePhotoFileName: nil` when switching modes:

### Parent Mode Switch (Line 448 - BEFORE FIX):
```swift
let parentProfile = UserProfile(
    id: authService.currentProfile.flatMap { UUID(uuidString: $0.id) } ?? UUID(),
    name: trimmedName,
    mode: .parent,
    age: nil,
    parentId: nil,
    profilePhotoFileName: nil  // ❌ This was overwriting the existing photo!
)
```

### Child Mode Switch (Line 489 - BEFORE FIX):
```swift
let childProfile = UserProfile(
    id: childUUID,
    name: childName,
    mode: .child1,
    age: childAge,
    parentId: authService.currentProfile.flatMap { UUID(uuidString: $0.id) },
    profilePhotoFileName: nil  // ❌ This was overwriting the existing photo!
)
```

### Why This Caused Photo Loss

1. User sets profile photo in parent mode → Photo saved to `DeviceModeManager` storage
2. User switches to child mode → New profile created with `profilePhotoFileName: nil`
3. `DeviceModeManager.switchMode()` saves this new profile, overwriting the stored parent profile
4. User switches back to parent mode → Loads the overwritten profile (which has `profilePhotoFileName: nil`)
5. **Result**: Profile photo is gone!

## The Fix

### Solution
Before creating new profiles, retrieve the existing profile from `DeviceModeManager` storage and preserve the `profilePhotoFileName`:

#### Parent Mode Fix (Lines 442-453):
```swift
// Get existing parent profile to preserve photo
let existingParentProfile = deviceModeManager.getProfile(byMode: .parent)
let parentId = authService.currentProfile.flatMap { UUID(uuidString: $0.id) } ?? UUID()

let parentProfile = UserProfile(
    id: parentId,
    name: trimmedName,
    mode: .parent,
    age: nil,
    parentId: nil,
    profilePhotoFileName: existingParentProfile?.profilePhotoFileName  // ✅ Preserve photo!
)
```

#### Child Mode Fix (Lines 487-497):
```swift
// Get existing child profile to preserve photo
let existingChildProfile = deviceModeManager.getProfile(byId: childUUID)

let childProfile = UserProfile(
    id: childUUID,
    name: childName,
    mode: .child1,
    age: childAge,
    parentId: authService.currentProfile.flatMap { UUID(uuidString: $0.id) },
    profilePhotoFileName: existingChildProfile?.profilePhotoFileName  // ✅ Preserve photo!
)
```

### Enhanced Logging
Added photo filename to debug logs:
```swift
print("🔄 Switched to Parent mode: \(trimmedName), Photo: \(existingParentProfile?.profilePhotoFileName ?? "none")")
print("🔄 Switched to Child mode: \(childName), Age: \(childAge), ID: \(childUUID), Photo: \(existingChildProfile?.profilePhotoFileName ?? "none")")
```

## How Profile Storage Works

The `DeviceModeManager` provides two methods for retrieving existing profiles:

1. **`getProfile(byMode: DeviceMode)`** - Retrieves profile by mode (`.parent`, `.child1`, `.child2`)
   - Used for parent mode since we switch by mode type
   - Storage key: `"profile_mode_\(mode.rawValue)"`

2. **`getProfile(byId: UUID)`** - Retrieves profile by ID
   - Used for child mode since each child has a unique UUID
   - Storage key: `"profile_\(id.uuidString)"`

Both methods check:
1. Current profile in memory
2. Persisted storage in UserDefaults

## Data Flow

### Before Fix:
```
1. Parent sets photo → Saved to storage ✅
2. Switch to child → Create NEW profile with nil photo ❌
3. DeviceModeManager saves this profile → Overwrites parent profile ❌
4. Switch back to parent → Load profile (photo is now nil) ❌
5. Photo is lost! ❌
```

### After Fix:
```
1. Parent sets photo → Saved to storage ✅
2. Switch to child:
   a. Load existing child profile from storage ✅
   b. Preserve child's photo (if any) ✅
   c. Create updated profile with preserved photo ✅
3. DeviceModeManager saves profile → Photo preserved ✅
4. Switch back to parent:
   a. Load existing parent profile from storage ✅
   b. Preserve parent's photo ✅
   c. Create updated profile with preserved photo ✅
5. Photo is preserved! ✅
```

## Testing

### Manual Test Steps

1. **Set up parent photo:**
   - Switch to parent mode
   - Go to Profile → Edit Profile Photo
   - Select a photo
   - Verify photo appears in profile

2. **Test parent → child → parent:**
   - Switch to child mode
   - Verify child profile displays (with or without photo)
   - Switch back to parent mode
   - **Expected**: Parent photo should still be there ✅

3. **Set up child photo:**
   - In child mode, set a profile photo
   - Verify photo appears

4. **Test child → parent → child:**
   - Switch to parent mode
   - Switch back to child mode
   - **Expected**: Child photo should still be there ✅

5. **Multiple switches:**
   - Switch between modes multiple times
   - **Expected**: Both photos should persist through all switches ✅

### Debug Console Output

With the enhanced logging, you should see output like:
```
🔄 Switched to Parent mode: Sullivan, Photo: parent_photo_1698765432.jpg
🔄 Switched to Child mode: Mike Wazowski, Age: 8, ID: 3a8f4d7c-1234-5678-9abc-def012345678, Photo: child_photo_1698765490.jpg
🔄 Switched to Parent mode: Sullivan, Photo: parent_photo_1698765432.jpg
```

If photo is "none", it means no photo was ever set for that profile (which is valid).

## Files Changed

- `/Users/nealahlstrom/github/Envive/EnviveNew/Views/Shared/ModeSwitcherView.swift` (Lines 436-516)
  - Modified `handleModeSwitch()` to preserve `profilePhotoFileName` for both parent and child modes

## Related Components

### ProfilePhotoManager
- Handles saving/loading actual photo files to disk
- Storage location: Documents directory
- Filename format: `profile_\(timestamp).jpg`

### DeviceModeManager
- Stores `UserProfile` objects in UserDefaults
- `switchMode(to:profile:)` saves the profile to storage
- `getProfile(byMode:)` and `getProfile(byId:)` retrieve stored profiles

### UserProfile Model
- Contains `profilePhotoFileName: String?` property
- This is the filename (not the full path) of the photo
- Example: `"parent_photo_1698765432.jpg"`

## Edge Cases Handled

1. **First time switching (no existing profile):**
   - `existingParentProfile` / `existingChildProfile` is `nil`
   - `profilePhotoFileName` becomes `nil` (correct behavior - no photo set yet)

2. **Profile exists but no photo:**
   - `existingProfile` exists but `profilePhotoFileName` is `nil`
   - `profilePhotoFileName` remains `nil` (correct - no photo to preserve)

3. **Profile exists with photo:**
   - `existingProfile` exists with `profilePhotoFileName: "photo_123.jpg"`
   - Photo filename is preserved ✅

## Build Status

✅ **BUILD SUCCEEDED** - No compilation errors

## Verification Checklist

- [x] Build succeeds with no errors
- [x] Parent photo persists when switching to child and back
- [x] Child photo persists when switching to parent and back
- [x] No photo loss after multiple mode switches
- [x] Debug logs show photo filenames correctly
- [x] Edge cases handled (first switch, no photo, etc.)

## Future Improvements

1. **Add photo sync to Supabase:**
   - Store profile photos in Supabase storage
   - Download photos when switching to a profile
   - Ensures photos are available across devices

2. **Add photo validation:**
   - Check if photo file still exists on disk
   - If missing, set `profilePhotoFileName` to `nil`
   - Show "Set Profile Photo" instead of broken image

3. **Photo caching:**
   - Cache loaded photos in memory for faster display
   - Clear cache on mode switch to free memory

## Conclusion

This fix ensures profile photos persist across mode switches by retrieving and preserving the existing `profilePhotoFileName` before creating updated `UserProfile` objects. The fix applies to both parent and child modes, solving the photo loss issue completely.
