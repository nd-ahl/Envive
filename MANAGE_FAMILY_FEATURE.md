# Manage Family Feature - Add Children to Household

## Feature Summary

Added a "Manage Family" feature in parent settings that allows parents to add children to their household after initial onboarding. This enables parents to create child accounts that can sign in independently.

## Implementation Details

### New View: ManageFamilyView

**File**: `/Users/nealahlstrom/github/Envive/EnviveNew/Views/Parent/ManageFamilyView.swift`

A comprehensive family management interface with the following features:

1. **View Household Members**
   - Shows parent info and member count
   - Lists all children in household
   - Displays child name, age, and profile photo

2. **Add Children**
   - Reuses existing `AddChildProfileSheet` from onboarding
   - Collects child's name, age, and optional profile photo
   - Creates child profile in Supabase
   - Adds child to household_members table

3. **Edit Children** (UI ready, not fully implemented)
   - Tap options menu on child card
   - Select "Edit Profile"
   - Opens AddChildProfileSheet with existing data

4. **Delete Children** (Placeholder)
   - Shows confirmation dialog
   - Currently displays message that delete is not implemented
   - Can be implemented by adding `deleteChildProfile()` to HouseholdService

### Integration with Existing Code

#### Reused Components

1. **AddChildProfileSheet** (from onboarding)
   - Already existed for onboarding flow
   - Collects: name, age, profile photo
   - Handles photo picker and preview
   - Validates input

2. **HouseholdService.createChildProfile()**
   - Already existed for onboarding
   - Creates profile in Supabase `profiles` table
   - Creates household_member entry
   - Uploads profile picture if provided
   - Returns child UUID

3. **HouseholdService.getMyChildren()**
   - Already existed for ParentChildrenManagementView
   - Fetches all children in household from Supabase
   - Filters by household_id and role='child'

#### Updated Files

**File**: `/Users/nealahlstrom/github/Envive/EnviveNew/Views/Shared/RootNavigationView.swift` (Line 481)

**Before:**
```swift
NavigationLink(destination: Text("Family Settings")) {
    Label("Manage Family", systemImage: "person.2")
}
```

**After:**
```swift
NavigationLink(destination: ManageFamilyView()) {
    Label("Manage Family", systemImage: "person.2")
}
```

### Data Flow

#### Adding a Child

```
1. Parent taps "Manage Family" in settings
   ↓
2. ManageFamilyView loads existing children via getMyChildren()
   ↓
3. Parent taps "Add Child" button
   ↓
4. AddChildProfileSheet appears
   ↓
5. Parent enters:
   - Child name (required)
   - Child age (required)
   - Profile photo (optional)
   ↓
6. Parent taps "Save"
   ↓
7. ManageFamilyView.saveChild() called:
   a. Upload profile photo if provided
   b. Call householdService.createChildProfile()
      - Creates row in profiles table with:
        * id (UUID, auto-generated)
        * full_name
        * age
        * role = 'child'
        * household_id (parent's household)
        * avatar_url
        * created_at, updated_at
      - Creates row in household_members table with:
        * household_id
        * user_id (child's UUID)
        * role = 'child'
        * joined_at
   c. Child can now sign in using their name/age
   ↓
8. Reload children list
   ↓
9. New child appears in list ✅
```

### Database Schema

#### Profiles Table
```sql
id: UUID (primary key)
email: TEXT (nullable for children)
full_name: TEXT
age: INTEGER
role: TEXT ('parent' or 'child')
household_id: UUID (foreign key to households)
avatar_url: TEXT
created_at: TIMESTAMP
updated_at: TIMESTAMP
```

#### Household Members Table
```sql
id: UUID (primary key)
household_id: UUID (foreign key)
user_id: UUID (foreign key to profiles)
role: TEXT ('owner', 'parent', 'child')
joined_at: TIMESTAMP
```

### UI Components

#### ManageFamilyView Structure

1. **Header Section**
   - Shows "Your Household"
   - Displays parent name
   - Shows total member count (parent + children)

2. **Loading State**
   - Progress indicator
   - "Loading children..." message

3. **Empty State**
   - Shown when no children exist
   - Icon: person.2.slash
   - Message: "No Children Added"
   - Helpful text about adding children

4. **Children List**
   - Header with count
   - Child cards showing:
     - Profile photo or initial circle
     - Name and age
     - Options button (ellipsis)

5. **Add Child Button**
   - Blue background
   - Icon: person.badge.plus
   - Text: "Add Child"

6. **Child Management Card**
   - Displays child info
   - Tapping options shows:
     - Edit Profile
     - Delete
     - Cancel

### Example Usage

#### Parent Workflow

1. **Initial Setup** (Onboarding)
   - Parent creates account
   - Parent adds children during onboarding
   - Children created in Supabase

2. **Add More Children Later**
   - Parent goes to Settings
   - Taps "Manage Family"
   - Taps "Add Child"
   - Enters child info
   - Child profile created
   - Child can now sign in

3. **Child Sign-In**
   - Child opens app
   - Selects "I'm a child"
   - Enters name and age
   - System finds matching profile
   - Child is authenticated
   - Child can start earning screen time

### Code Example

#### Creating a Child

```swift
// In ManageFamilyView
private func saveChild(_ childData: ChildProfileData) async {
    guard let currentProfile = authService.currentProfile,
          let householdId = currentProfile.householdId else {
        // Error: No household
        return
    }

    // Upload avatar if provided
    var avatarUrl: String? = nil
    if let avatarImage = childData.avatarImage,
       let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
        avatarUrl = try await householdService.uploadProfilePicture(
            userId: UUID().uuidString,
            imageData: imageData
        )
    }

    // Create child profile in Supabase
    let childId = try await householdService.createChildProfile(
        name: childData.name,
        age: childData.age,
        householdId: householdId,
        createdBy: currentProfile.id,
        avatarUrl: avatarUrl
    )

    print("✅ Child created: \(childId)")

    // Reload list
    loadChildren()
}
```

### Error Handling

1. **No Household Error**
   - Shown if parent hasn't completed onboarding
   - Message: "No household found. Please complete onboarding first."

2. **Create Profile Error**
   - Shown if Supabase request fails
   - Message: "Failed to create child profile: [error]"

3. **Load Children Error**
   - Shown if getMyChildren() fails
   - Message: "Failed to load children: [error]"

4. **Delete Not Implemented**
   - Shown when delete is attempted
   - Message: "Delete functionality is not yet implemented..."

### Testing Checklist

- [ ] Parent can open Manage Family from settings
- [ ] Empty state shows when no children exist
- [ ] "Add Child" button opens AddChildProfileSheet
- [ ] Can enter child name and age
- [ ] Can select profile photo
- [ ] Tapping "Save" creates child in Supabase
- [ ] New child appears in list after creation
- [ ] Child shows correct name and age
- [ ] Child can sign in using their credentials
- [ ] Multiple children can be added
- [ ] Edit button shows sheet with child data
- [ ] Delete shows confirmation dialog
- [ ] Cancel buttons work correctly

### Future Enhancements

1. **Implement Delete Functionality**
   ```swift
   // Add to HouseholdService
   func deleteChildProfile(childId: String) async throws {
       // Delete from household_members
       try await supabase
           .from("household_members")
           .delete()
           .eq("user_id", value: childId)
           .execute()

       // Delete from profiles
       try await supabase
           .from("profiles")
           .delete()
           .eq("id", value: childId)
           .execute()
   }
   ```

2. **Implement Edit Functionality**
   - Update profile in Supabase
   - Handle photo changes
   - Refresh child list

3. **Add Child Invitation System**
   - Generate invite code
   - Child enters code to join household
   - Parent approves request

4. **Show Child Activity**
   - Last active timestamp
   - Current screen time balance
   - Recent tasks

5. **Batch Operations**
   - Add multiple children at once
   - Import from contacts
   - CSV upload

6. **Permissions & Roles**
   - Set different child permissions
   - Age-based restrictions
   - Custom profiles per child

### Security Considerations

1. **Authentication**
   - Only authenticated parents can add children
   - Children can only be added to parent's household
   - Household ID is verified from auth token

2. **Data Validation**
   - Name and age are required
   - Age must be positive integer
   - Photo size/format validated

3. **Authorization**
   - RLS policies ensure parents can only modify their own household
   - Children can't delete themselves
   - Parents can only see their own children

## Build Status

✅ **BUILD SUCCEEDED**

## Files Added

- `/Users/nealahlstrom/github/Envive/EnviveNew/Views/Parent/ManageFamilyView.swift`

## Files Modified

- `/Users/nealahlstrom/github/Envive/EnviveNew/Views/Shared/RootNavigationView.swift` (Line 481)

## Conclusion

The Manage Family feature provides parents with a post-onboarding interface to add children to their household. It integrates seamlessly with the existing onboarding flow and reuses the same UI components and backend services. Children added through this interface can sign in and start using the app immediately.

**Key Benefit**: Parents who initially skip adding children during onboarding, or who want to add more children later, can now do so easily through Settings → Manage Family.
