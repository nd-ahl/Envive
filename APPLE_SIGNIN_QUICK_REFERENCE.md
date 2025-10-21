# Apple Sign In - Quick Reference Sheet

✅ **I've already done this for you in Xcode:**
- Added Sign in with Apple capability to EnviveNew.entitlements
- Your code is ready to use Apple Sign In

---

## 📋 Your Project Info

**App Bundle ID:** `com.neal.envivenew`

**Supabase Project URL:** `vevcxsjcqwlmmlchfymn.supabase.co`

**Supabase Callback URL:** `https://vevcxsjcqwlmmlchfymn.supabase.co/auth/v1/callback`

---

## 🔑 What You Need to Collect

As you go through the setup, collect these values:

1. **Services ID** (you create this): `com.neal.envivenew.signin` ✏️
2. **Team ID** (from Apple Developer): `__________` ✏️
3. **Key ID** (when you download .p8 file): `__________` ✏️
4. **.p8 Key File** (download and save) ✏️

---

## 📝 3-Minute Setup Checklist

### In Apple Developer (https://developer.apple.com/account)

**Step 1: Create Services ID** (2 min)
- [ ] Go to Identifiers → Click "+" → Select "Services IDs"
- [ ] Enter identifier: `com.neal.envivenew.signin`
- [ ] Enable "Sign in with Apple"
- [ ] Configure it with:
  - Domain: `vevcxsjcqwlmmlchfymn.supabase.co`
  - Return URL: `https://vevcxsjcqwlmmlchfymn.supabase.co/auth/v1/callback`

**Step 2: Create Key** (1 min)
- [ ] Go to Keys → Click "+"
- [ ] Name it "Envive Apple Sign In"
- [ ] Enable "Sign in with Apple"
- [ ] Download the .p8 file (ONLY ONE CHANCE!)
- [ ] Save the Key ID (10-character code)

**Step 3: Get Team ID** (30 sec)
- [ ] Go to https://developer.apple.com/account
- [ ] Copy your Team ID (top right)

---

### In Supabase (https://supabase.com/dashboard/project/vevcxsjcqwlmmlchfymn/auth/providers)

**Step 1: Enable Apple Provider** (1 min)
- [ ] Find "Apple" in the providers list
- [ ] Toggle it ON
- [ ] Fill in Services ID: `com.neal.envivenew.signin`

**Step 2: Generate Client Secret**
- [ ] Use Supabase's JWT helper (if available) OR
- [ ] Go to https://jwt.io and create a JWT with:
  - Team ID
  - Services ID
  - Key ID
  - .p8 key contents
- [ ] Paste the JWT into "Secret (for OAuth)" field

**Step 3: Save**
- [ ] Click Save
- [ ] Done! 🎉

---

## 🧪 Testing

**Important:** Apple Sign In only works on **real devices**, not simulators!

1. Open Xcode
2. Select your iPhone (not simulator)
3. Build and run (⌘R)
4. Go through onboarding
5. Tap "Sign in with Apple"
6. You should see Apple's authentication screen!

---

## 🆘 Common Issues

**"Invalid client"**
→ Check Services ID matches in both Apple and Supabase

**"Invalid redirect URI"**
→ Make sure you added the EXACT callback URL with https://

**Button doesn't show**
→ Must test on real device, not simulator

**"Invalid JWT"**
→ Regenerate with correct Team ID, Key ID, and .p8 contents

---

## 📞 Need Help?

If you get stuck:
1. Tell me which step you're on
2. What error message you see
3. I'll help debug!

The full detailed guide is in `APPLE_SIGNIN_SETUP.md`
