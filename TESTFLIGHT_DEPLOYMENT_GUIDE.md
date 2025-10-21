# TestFlight Deployment Guide for Envive

## Pre-Flight Checklist

Before deploying to TestFlight, ensure everything is working:

### ✅ Core Features Working
- [x] Child can enter household code and see profiles
- [x] Child can select profile and complete onboarding
- [x] Parent can sign up and create household
- [x] Parent can sign in with existing account
- [x] Password reset flow works
- [x] Role-based views (child sees child view, parent sees parent view)
- [x] Profile data shows correctly in settings

### ⚠️ Pre-Deployment Tasks
- [ ] Test on physical device (not just simulator)
- [ ] Remove database cleanup script from production
- [ ] Check for console log messages (clean up sensitive data)
- [ ] Verify Supabase credentials are correct
- [ ] Test dark mode (already fixed)
- [ ] Test all onboarding flows end-to-end

---

## Step 1: Prepare Your Project

### 1.1 Update Version and Build Number

1. Open `EnviveNew.xcodeproj` in Xcode
2. Select the **EnviveNew** target (blue icon)
3. Go to **General** tab
4. Update:
   - **Version**: `1.0.0` (or your desired version)
   - **Build**: `1` (increment for each upload)

### 1.2 Set Release Configuration

1. Go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** in left sidebar
3. Change **Build Configuration** to **Release**
4. Click **Close**

### 1.3 Select a Real Device or "Any iOS Device"

1. In the top toolbar, click the device selector
2. Choose **Any iOS Device (arm64)** (NOT a simulator!)

---

## Step 2: Archive Your App

### 2.1 Create Archive

1. Go to **Product** → **Archive**
2. Wait for the build to complete (5-10 minutes)
3. The **Organizer** window will open automatically

### 2.2 Common Build Errors & Fixes

**Error: "No accounts with App Store Connect access"**
- Fix: Go to Xcode → Settings → Accounts → Add your Apple ID

**Error: "Signing certificate issues"**
- Fix: Select your team in Signing & Capabilities
- Enable "Automatically manage signing"

**Error: "Provisioning profile doesn't include device"**
- Fix: Register your device at developer.apple.com
- Or use "Automatically manage signing"

---

## Step 3: Upload to App Store Connect

### 3.1 Distribute Archive

1. In **Organizer**, select your archive
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Click **Next**
5. Choose **Upload** (not Export)
6. Click **Next**
7. Select **Automatically manage signing** (recommended)
8. Click **Next**
9. Review the summary
10. Click **Upload**

### 3.2 Wait for Processing

- Upload takes 5-15 minutes depending on internet speed
- Processing in App Store Connect takes 10-30 minutes
- You'll get an email when it's ready

---

## Step 4: Set Up TestFlight

### 4.1 Go to App Store Connect

1. Visit https://appstoreconnect.apple.com
2. Sign in with your Apple ID
3. Click **My Apps**
4. Select **Envive** (or create new app if first time)

### 4.2 Create App (If First Time)

**If this is your first TestFlight:**

1. Click **+** button
2. Select **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: Envive
   - **Primary Language**: English
   - **Bundle ID**: `com.yourcompany.EnviveNew` (must match Xcode)
   - **SKU**: `envive-001` (unique identifier)
   - **User Access**: Full Access
4. Click **Create**

### 4.3 Navigate to TestFlight

1. In your app page, click **TestFlight** tab
2. Wait for your build to appear (10-30 minutes after upload)
3. You'll see: **Version 1.0.0 (1) - Processing** → **Ready to Submit**

---

## Step 5: Configure TestFlight Build

### 5.1 Add Build Information

1. Click on your build number
2. Fill in **Test Details**:

**What to Test:**
```
Welcome to Envive TestFlight!

This is an early version of Envive - the family task management app that converts chores into screen time.

Key Features to Test:
✅ Parent Flow:
- Sign up with Apple or Email
- Create household
- Add child profiles
- View household invite code

✅ Child Flow:
- Enter household invite code
- Select your profile
- Complete onboarding
- View tasks and profile

Known Issues:
- Still in active development
- Database may be reset periodically

Please report any bugs or issues!

Test Account (Optional):
- Household Code: 834228
- Child Profile: Jesse Pinkman (age 16)
```

3. Click **Save**

### 5.2 Export Compliance

1. Answer **"Does your app use encryption?"**
   - Select **YES** (Supabase uses HTTPS/TLS)
2. Answer **"Is it exempt from regulations?"**
   - Select **YES** (standard HTTPS is exempt)
3. Confirm **Export Compliance**

### 5.3 Submit for Review (Internal Testing)

1. Click **Submit for Review**
2. Wait for Apple's automated review (usually instant for TestFlight)

---

## Step 6: Add Testers

### 6.1 Internal Testing Group

**Internal testers (up to 100) - no review needed:**

1. Go to **TestFlight** → **Internal Testing**
2. Click **+** next to **Internal Testers**
3. Add testers by email (must be in App Store Connect)
4. Select the build to test
5. Click **Add**

Internal testers get access immediately!

### 6.2 External Testing Group (Optional)

**External testers (up to 10,000) - requires review:**

1. Go to **TestFlight** → **External Testing**
2. Click **+** to create a new group
3. Name it (e.g., "Beta Testers")
4. Add testers by email or public link
5. Submit for TestFlight review (1-2 days)

---

## Step 7: Install on Your Device

### 7.1 Testers Install TestFlight App

1. Download **TestFlight** from App Store
2. Open TestFlight app
3. You'll see **Envive** appear automatically (if added as tester)
4. Tap **Install**

### 7.2 Test Your App

**Parent Test:**
1. Open Envive from TestFlight
2. Tap "Get Started"
3. Go through parent onboarding
4. Create account with email/Apple
5. Create household
6. Add child profiles
7. Note the household invite code
8. Complete onboarding

**Child Test:**
1. Delete app and reinstall from TestFlight
2. Tap "Get Started"
3. Select "I'm a Child"
4. Enter household code from parent
5. Select child profile
6. Complete onboarding
7. Verify child view shows

---

## Step 8: Update & Iterate

### 8.1 Upload New Build

When you make changes:

1. **Increment Build Number** in Xcode (e.g., 1 → 2)
2. **Archive** again (Product → Archive)
3. **Upload** to App Store Connect
4. Wait for processing
5. **Submit** new build to TestFlight

**Note:** Version stays same (1.0.0), build increments (1, 2, 3...)

### 8.2 Notify Testers

1. In TestFlight tab, click your build
2. Click **Notify Testers**
3. Write update notes:
   ```
   Build 2 Updates:
   - Fixed parent onboarding loop
   - Improved dark mode contrast
   - Added password reset flow
   ```
4. Click **Send**

---

## Troubleshooting

### "Archive" is Grayed Out

**Fix:**
- Make sure you selected **Any iOS Device** (not simulator)
- Build the project first (Cmd+B)

### Build Not Appearing in App Store Connect

**Check:**
- Did upload complete successfully?
- Wait 10-30 minutes for processing
- Check email for errors from Apple

### "Invalid Bundle ID"

**Fix:**
- Bundle ID in Xcode must match App Store Connect
- Go to Xcode → Target → Signing & Capabilities
- Verify Bundle Identifier

### Testers Not Getting Invite

**Check:**
- Email address matches Apple ID
- Check spam folder
- Tester needs TestFlight app installed
- Internal testers must be in App Store Connect team

---

## Production Release Checklist (After Testing)

When ready to release to App Store:

- [ ] Thorough testing on TestFlight
- [ ] All major bugs fixed
- [ ] App Store screenshots prepared
- [ ] App Store description written
- [ ] Privacy policy URL ready
- [ ] Support URL ready
- [ ] Age rating determined
- [ ] App Store review guidelines checked

---

## Quick Command Reference

```bash
# Clean build folder
Cmd+Shift+K

# Build
Cmd+B

# Archive
Product → Archive

# View archives
Window → Organizer
```

---

## Important Notes

### Database Cleanup

Before TestFlight, consider:
- Keeping test data (Walter White household) for testers to use
- OR providing fresh accounts for each tester
- Document test credentials in "What to Test"

### Supabase Limits

Free tier limits:
- 500 MB database
- 1 GB bandwidth/month
- 50,000 monthly active users

Monitor usage at: https://app.supabase.com

### Apple Developer Program

Required for TestFlight:
- $99/year Apple Developer account
- Enrollment at: https://developer.apple.com/programs/

---

## Success Metrics

After deploying to TestFlight, track:
- [ ] Number of crashes
- [ ] User feedback on onboarding
- [ ] Household creation success rate
- [ ] Child profile selection success rate
- [ ] Authentication issues
- [ ] Dark mode display issues

---

## Next Steps

1. **Test on physical device first** (not simulator!)
2. **Archive and upload**
3. **Set up TestFlight**
4. **Add yourself as tester**
5. **Install and test**
6. **Add more testers**
7. **Iterate based on feedback**

**Good luck with your TestFlight launch! 🚀**
