# Manual Auth User Deletion Instructions

If the SQL script fails to delete `auth.users` (likely due to Supabase restrictions), follow these steps:

## Why Manual Deletion May Be Required

Supabase Auth manages the `auth.users` table with special protections. Direct SQL deletion may be blocked for security reasons.

---

## Step-by-Step Manual Deletion

### 1. Open Supabase Dashboard
- Go to: https://supabase.com/dashboard
- Sign in to your account
- Select your Envive project

### 2. Navigate to Authentication
- Click **"Authentication"** in the left sidebar
- Click **"Users"** sub-menu

### 3. View Current Users
You should see all registered users, including:
- Email addresses (or Apple ID emails)
- Sign-up dates
- Last sign-in times
- User IDs

### 4. Delete Users One-by-One
For each user:
1. Click the **"..."** menu (three dots) on the right side of the user row
2. Select **"Delete user"**
3. Confirm the deletion in the popup
4. Repeat for all users

### 5. Verify Deletion
- The user list should be empty
- No users should be shown

---

## Alternative: Bulk Deletion via Dashboard

Some Supabase dashboards support bulk operations:
1. Check the checkbox next to each user (or "Select All" if available)
2. Look for a bulk action menu
3. Choose "Delete selected users"
4. Confirm deletion

---

## Verification

After manual deletion:
1. Go back to **SQL Editor**
2. Run this query:
```sql
SELECT COUNT(*) as remaining_users FROM auth.users;
```
3. Should return `0`

---

## What Happens Next

Once all auth users are deleted:
- ✅ Your Apple ID is no longer associated with any account
- ✅ You can sign in with the same Apple ID to create a fresh account
- ✅ App will treat you as a brand new user
- ✅ Onboarding will run from the beginning

---

## Troubleshooting

### If users won't delete:
1. Check for any RLS policies blocking deletion
2. Verify you have Owner/Admin access to the project
3. Try using Supabase CLI: `supabase db reset`
4. Contact Supabase support if issues persist

### If you accidentally delete the wrong user:
- Cannot be undone
- User will lose access immediately
- They would need to create a new account
