# Envive Database Management

This document explains how to manage the Supabase database for the Envive app.

## Clearing the Database

### Purpose
The `clear_database.sh` script allows you to completely reset the database, removing all user accounts and data. This is useful for:
- Development and testing
- Starting fresh after testing
- Reusing email addresses for new signups

### What Gets Deleted
The script clears:
1. **Auth Users** - All authentication accounts (allows email reuse)
2. **Profiles** - All user profile records
3. **Households** - All household/family groups
4. **Household Members** - All household membership records

### How to Use

**⚠️ WARNING: This operation is IRREVERSIBLE. All data will be permanently deleted.**

1. **Navigate to the project directory:**
   ```bash
   cd /Users/nealahlstrom/github/Envive
   ```

2. **Run the script:**
   ```bash
   ./clear_database.sh
   ```

3. **Confirm when prompted:**
   ```
   Are you sure you want to delete ALL data? (type 'yes' to confirm): yes
   ```

### Example Output
```
🗑️  Envive Database Clear Script
================================

⚠️  WARNING: This will DELETE ALL data from the following tables:
   - profiles
   - households
   - household_members
   - auth.users (via Supabase auth API)

🚀 Starting database clear...

🗑️  Clearing table: household_members...
   ✅ Cleared household_members
🗑️  Clearing table: profiles...
   ✅ Cleared profiles
🗑️  Clearing table: households...
   ✅ Cleared households
🗑️  Deleting all authentication users...
   ✅ Deleted 4 auth user(s)

✅ Database clear complete!

📧 You can now reuse the same email addresses for new signups.
```

## Verification

After clearing, you can verify the database is empty:

### Check Profiles Table
```bash
curl -s -X GET "https://vevcxsjcqwlmmlchfymn.supabase.co/rest/v1/profiles?select=count" \
  -H "apikey: YOUR_SERVICE_KEY" \
  -H "Prefer: count=exact"
```
**Expected:** `[{"count":0}]`

### Check Households Table
```bash
curl -s -X GET "https://vevcxsjcqwlmmlchfymn.supabase.co/rest/v1/households?select=count" \
  -H "apikey: YOUR_SERVICE_KEY" \
  -H "Prefer: count=exact"
```
**Expected:** `[{"count":0}]`

### Check Auth Users
```bash
curl -s -X GET "https://vevcxsjcqwlmmlchfymn.supabase.co/auth/v1/admin/users" \
  -H "apikey: YOUR_SERVICE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_KEY"
```
**Expected:** `{"users":[]}`

## What Happens After Clearing

### Immediate Effects:
- ✅ All user accounts deleted
- ✅ All email addresses can be reused
- ✅ All household data removed
- ✅ All child profiles removed

### What's NOT Deleted:
- ❌ Local app data (stored on device)
- ❌ Task templates (predefined tasks)
- ❌ App configuration
- ❌ Badge definitions

### Next Steps:
1. **Clear local app data** (optional):
   - Delete and reinstall the app, OR
   - Use Settings → Reset App

2. **Create new accounts:**
   - Sign up with any email (including previously used ones)
   - Create new households
   - Add new child profiles

## Technical Details

### Database Structure
```
auth.users (Supabase Auth)
    ↓
profiles (user data)
    ↓
households (family groups)
    ↓
household_members (membership relationships)
```

### Deletion Order
The script deletes in reverse dependency order:
1. `household_members` (depends on both profiles and households)
2. `profiles` (depends on auth.users)
3. `households` (standalone)
4. `auth.users` (root level - allows email reuse)

### API Keys Used
- **Service Role Key** - Full admin access to database
- Used for bypassing Row Level Security (RLS) policies
- Required for bulk deletion operations

## Troubleshooting

### "Permission Denied" Error
**Cause:** Using anon key instead of service key
**Fix:** Ensure script uses the service_role key (not anon key)

### "Foreign Key Constraint" Error
**Cause:** Deletion order incorrect
**Fix:** Script already handles correct order (members → profiles → households)

### "Users Still Exist" After Clearing
**Cause:** Auth deletion failed silently
**Fix:** Check Supabase dashboard → Authentication → Users
- Manually delete remaining users if needed

### Cannot Reuse Email Address
**Cause:** User not fully deleted from auth.users
**Fix:** Run script again, or manually delete user from Supabase dashboard

## Safety Recommendations

### For Production Use:
❌ **DO NOT** use this script in production
❌ **DO NOT** commit service keys to git
✅ **DO** use environment variables for keys
✅ **DO** implement proper backup strategy
✅ **DO** require additional confirmation for production

### For Development Use:
✅ Safe to use frequently during development
✅ Allows rapid testing of onboarding flows
✅ Enables email reuse for test accounts
⚠️ Always confirm before running

## Alternative: Supabase Dashboard

You can also clear data via Supabase dashboard:

1. Go to: https://supabase.com/dashboard/project/vevcxsjcqwlmmlchfymn
2. Navigate to **Table Editor**
3. For each table (household_members, profiles, households):
   - Select all rows
   - Click "Delete selected rows"
4. Navigate to **Authentication → Users**
   - Select all users
    - Click "Delete users"

**Note:** Dashboard method is slower but provides visual confirmation.

## Support

If you encounter issues:
1. Check Supabase dashboard for actual data state
2. Verify API keys are correct and have service role access
3. Check table relationships and foreign keys
4. Review Supabase logs for detailed error messages

---

**Last Updated:** January 2025
**Script Version:** 1.0
**Supabase Project:** vevcxsjcqwlmmlchfymn
