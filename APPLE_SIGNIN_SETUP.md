# Apple Sign In Setup Guide

I've already added the Sign in with Apple capability to your Xcode project! ✅

Now you need to configure it in your Apple Developer account and Supabase. Follow these steps:

---

## Part 1: Apple Developer Account Setup

### Step 1: Get Your Bundle ID

Your app's Bundle ID is: **com.neal.EnviveNew**

(You'll need this for the next steps)

---

### Step 2: Create an App ID (if not already created)

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click the **"+"** button to create a new identifier
3. Select **"App IDs"** and click **Continue**
4. Select **"App"** and click **Continue**
5. Fill in:
   - **Description**: Envive
   - **Bundle ID**: com.neal.EnviveNew (Explicit)
6. Scroll down and check **"Sign in with Apple"**
7. Click **Continue**, then **Register**

**If your App ID already exists:**
1. Find it in the list and click on it
2. Scroll down and check **"Sign in with Apple"**
3. Click **Save**

---

### Step 3: Create a Services ID (REQUIRED for Supabase)

This is what Supabase needs to authenticate users.

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click the **"+"** button
3. Select **"Services IDs"** and click **Continue**
4. Fill in:
   - **Description**: Envive Sign In
   - **Identifier**: `com.neal.EnviveNew.signin` (this can be anything, but keep it related to your app)
5. Click **Continue**, then **Register**

**⚠️ SAVE THIS IDENTIFIER!** You'll need it for Supabase.

---

### Step 4: Configure the Services ID

1. In the Services IDs list, click on the one you just created
2. Check the box for **"Sign in with Apple"**
3. Click **Configure** next to "Sign in with Apple"
4. In the dialog that appears:
   - **Primary App ID**: Select your app (com.neal.EnviveNew)
   - **Domains and Subdomains**: Add `vevcxsjcqwlmmlchfymn.supabase.co`
   - **Return URLs**: Add `https://vevcxsjcqwlmmlchfymn.supabase.co/auth/v1/callback`
5. Click **Next**, then **Done**
6. Click **Continue**, then **Save**

**⚠️ Important URLs to add:**
```
Domain: vevcxsjcqwlmmlchfymn.supabase.co
Return URL: https://vevcxsjcqwlmmlchfymn.supabase.co/auth/v1/callback
```

---

### Step 5: Create a Sign in with Apple Key

This is the authentication key Supabase uses to verify Apple sign-ins.

1. Go to: https://developer.apple.com/account/resources/authkeys/list
2. Click the **"+"** button
3. Fill in:
   - **Key Name**: Envive Apple Sign In Key
4. Check the box for **"Sign in with Apple"**
5. Click **Configure** next to "Sign in with Apple"
6. Select your **Primary App ID**: com.neal.EnviveNew
7. Click **Save**
8. Click **Continue**, then **Register**

**⚠️ DOWNLOAD THE KEY FILE!**
- Click **Download** - you'll get a `.p8` file
- **SAVE THIS FILE!** You can only download it once!
- Also **SAVE THE KEY ID** shown on the page (it's a 10-character code like "ABC123DEFG")

---

### Step 6: Get Your Team ID

1. Go to: https://developer.apple.com/account
2. Look for **"Team ID"** on the right side of the page
3. **SAVE THIS!** It's a 10-character code

---

## Part 2: Supabase Configuration

Now let's connect everything to Supabase.

### Step 1: Open Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/vevcxsjcqwlmmlchfymn
2. Click **"Authentication"** in the left sidebar
3. Click **"Providers"** tab

---

### Step 2: Enable Apple Provider

1. Find **"Apple"** in the list of providers
2. Click to expand it
3. Toggle **"Enable Sign in with Apple"** to ON
4. Fill in the following:

**Services ID:**
```
com.neal.EnviveNew.signin
```
(The Services ID you created in Apple Developer)

**Client Secret (JWT):**
This is tricky - you need to generate a JWT token. But don't worry, I'll give you an easier method below.

---

### Step 3: Generate the Client Secret (JWT)

**Option A: Use Supabase's Helper (Easiest)**

Supabase has a helper tool! Let's use it:

1. In the Apple provider settings, look for a link that says **"Generate a JWT"** or similar
2. Fill in:
   - **Secret Key ID**: (The Key ID from your .p8 file download)
   - **Team ID**: (Your Apple Team ID)
   - **Client ID (Services ID)**: com.neal.EnviveNew.signin
   - **Secret Key**: (Open the .p8 file in a text editor and paste the contents)
3. Click **Generate** and it will create the JWT for you
4. Copy the generated JWT into the **"Secret (for OAuth)"** field

**Option B: Manual Method**

If Supabase doesn't have the helper, use this website:
1. Go to: https://jwt.io
2. In the **Payload** section, paste:
```json
{
  "iss": "YOUR_TEAM_ID",
  "iat": 1234567890,
  "exp": 1850000000,
  "aud": "https://appleid.apple.com",
  "sub": "com.neal.EnviveNew.signin"
}
```
3. Replace `YOUR_TEAM_ID` with your actual Team ID
4. In the **Verify Signature** section:
   - Select **ES256** algorithm
   - Paste your .p8 key content
   - Add the Key ID in the header section
5. Copy the generated JWT

---

### Step 4: Save Supabase Configuration

1. After filling in all the fields in Supabase
2. Click **Save**
3. Apple Sign In is now enabled! 🎉

---

## Part 3: Test It!

### Build and Run Your App

1. Open Xcode
2. Select a real device (not simulator) - Apple Sign In doesn't work in simulator
3. Build and run the app (⌘R)
4. Go through onboarding
5. When you reach the Sign In screen, tap **"Sign in with Apple"**
6. It should show the Apple authentication dialog!

---

## Quick Checklist

Before testing, make sure you have:

- [x] ✅ App ID created with Sign in with Apple enabled
- [ ] Services ID created (com.neal.EnviveNew.signin)
- [ ] Services ID configured with Supabase domain and callback URL
- [ ] Sign in with Apple Key created and downloaded (.p8 file)
- [ ] Team ID saved
- [ ] Key ID saved
- [ ] Supabase Apple provider enabled with all credentials
- [ ] App tested on a real device

---

## Troubleshooting

**Error: "Invalid client"**
- Check that your Services ID is correct in Supabase
- Make sure the Services ID is configured with the correct domains

**Error: "Invalid redirect URI"**
- Make sure you added the exact callback URL in Apple Developer:
  `https://vevcxsjcqwlmmlchfymn.supabase.co/auth/v1/callback`

**Apple Sign In button doesn't appear**
- Make sure you're testing on a real device, not simulator
- Check that the entitlements file has Sign in with Apple capability

**Error: "Invalid JWT"**
- Regenerate the JWT with the correct Team ID and Key
- Make sure the .p8 key content is correct

---

## Summary: What You Need

From Apple Developer:
1. **Services ID**: `com.neal.EnviveNew.signin`
2. **Team ID**: (10-character code)
3. **Key ID**: (10-character code from .p8 download)
4. **.p8 Key File**: (Downloaded file)

For Supabase:
1. Services ID → Goes in "Services ID" field
2. Generated JWT → Goes in "Secret (for OAuth)" field

---

## Need Help?

If you get stuck on any step, let me know:
- Which step you're on
- What error you're seeing
- I'll help you troubleshoot!

The hardest part is generating the JWT, but Supabase's helper makes it much easier!
