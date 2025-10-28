# Complete User Data Wipe - Summary and Approval Request

## Purpose
Wipe all user data from the Supabase database to allow the same Apple ID to create a fresh account.

---

## What Will Be Deleted

### 1. **Profiles Table** (`profiles`)
- All parent profiles
- All child profiles
- Includes: email, full_name, role, household_id, profile photos, ages, etc.

### 2. **Households Table** (`households`)
- All household records
- All invite codes
- Household names and metadata

### 3. **Household Members Table** (`household_members`)
- All household membership records
- Join dates and role assignments

### 4. **Task Verifications Table** (`task_verifications`)
- Any task verification records (if they exist)

### 5. **Auth Users Table** (`auth.users`)
- **CRITICAL**: All authentication records
- This is what allows Apple ID re-use
- Email addresses, sign-in history, etc.

---

## What Will NOT Be Deleted

✅ **Database Schema** - All table structures remain intact
✅ **Functions & Triggers** - All database functions stay
✅ **RLS Policies** - Row Level Security policies remain
✅ **Storage Buckets** - File storage configuration stays (but files may be orphaned)

---

## Important Warnings

### ⚠️ THIS ACTION IS PERMANENT AND IRREVERSIBLE

1. **All user data will be permanently deleted**
2. **Cannot be undone** - no backups will be kept
3. **Profile photos** in storage will become orphaned (not automatically deleted)
4. **All XP, tasks, badges, credibility scores** will be lost
5. **All household relationships** will be destroyed

### 🔐 Apple ID Re-use

- After wipe, the same Apple ID can sign up again
- App will treat it as a completely new user
- Onboarding will run from scratch
- New household and profiles will be created

### ⚠️ Potential Issue: Auth User Deletion

The `auth.users` table is managed by Supabase Auth. Depending on your Supabase configuration:
- Direct SQL deletion may be blocked by Supabase
- You may need to delete users from the **Supabase Dashboard** → **Authentication** → **Users** tab
- If SQL deletion fails, manual dashboard deletion is required

---

## How to Execute

### Option 1: SQL Editor (Recommended)

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Open file: `database/cleanup/WIPE_ALL_USER_DATA.sql`
4. **REVIEW STEP 1** - Check what data exists
5. **UNCOMMENT STEP 2** - Remove the `/*` and `*/` comments
6. **RUN THE SCRIPT**
7. **VERIFY STEP 3** - Confirm all counts are 0

### Option 2: Manual Deletion (If SQL fails)

1. Go to **Authentication** → **Users** in Supabase Dashboard
2. Delete all users manually
3. Go to **Table Editor** → **profiles** → Delete all rows
4. Go to **Table Editor** → **households** → Delete all rows
5. Go to **Table Editor** → **household_members** → Delete all rows

---

## After Wipe - What to Do

1. ✅ Sign out of the app on the device
2. ✅ Delete and reinstall the app (optional but recommended)
3. ✅ Sign in with Apple ID again
4. ✅ Complete onboarding from scratch
5. ✅ Create new household
6. ✅ Add child profiles again

---

## Estimated Data Loss

Based on typical usage, this will delete:
- **~1-5 parent profiles**
- **~1-10 child profiles**
- **~1-5 households**
- **~5-50 household member relationships**
- **~1-20 auth user records**
- **All associated XP, tasks, badges, credibility data**

---

## 🚨 FINAL APPROVAL REQUIRED

**Before proceeding, please confirm:**

- [ ] I understand all data will be permanently deleted
- [ ] I have reviewed what will be deleted
- [ ] I accept that this cannot be undone
- [ ] I want to proceed with the complete wipe

**Type "YES, WIPE ALL DATA" to confirm and proceed**

---

## Files Created

- `database/cleanup/WIPE_ALL_USER_DATA.sql` - The SQL wipe script
- `database/cleanup/WIPE_SUMMARY.md` - This summary document
