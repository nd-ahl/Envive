# Email Confirmation Setup Guide

**Status:** ✅ Code is production-ready with email confirmation enabled

---

## ✅ What's Already Configured

Your app is set up for email confirmation:

1. **SignUp Function** (`AuthenticationService.swift:58-66`)
   - ✅ Uses `redirectTo: URL(string: "envivenew://auth/callback")`
   - ✅ Sends confirmation email to user
   - ✅ Includes user metadata (full_name, role)

2. **Deep Link Handler** (`EnviveNewApp.swift:328-331`)
   - ✅ Handles `envivenew://auth/callback` URLs
   - ✅ Routes to `handleAuthCallback()` function

3. **Callback Processor** (`EnviveNewApp.swift:340-390`)
   - ✅ Extracts access_token and refresh_token
   - ✅ Sets session with confirmed tokens
   - ✅ Loads user profile
   - ✅ Continues onboarding flow

4. **URL Scheme** (`Info.plist:20`)
   - ✅ Registered: `envivenew://`

---

## 🔧 Required Supabase Configuration

You **MUST** configure these settings in Supabase Dashboard for email confirmation to work:

### Step 1: Set Site URL

1. Go to: **Supabase Dashboard** → **Settings** → **Auth** → **Site URL**
2. Set to:
   ```
   envivenew://
   ```
3. Click **Save**

---

### Step 2: Add Redirect URLs

1. Go to: **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Add these URLs to **Redirect URLs** (one per line):
   ```
   envivenew://auth/callback
   envivenew://reset-password
   envivenew://**
   ```
3. Click **Save**

**Why these URLs?**
- `envivenew://auth/callback` - Email confirmation and OAuth callbacks
- `envivenew://reset-password` - Password reset emails
- `envivenew://**` - Wildcard for any future deep links

---

### Step 3: Configure Email Template

1. Go to: **Supabase Dashboard** → **Authentication** → **Email Templates** → **Confirm signup**

2. Replace the default template with your custom template from `ENVIVE_EMAIL_TEMPLATE.html`

3. **Important Variables** to keep:
   - `{{ .ConfirmationURL }}` - The confirmation link (REQUIRED)
   - `{{ .Email }}` - User's email address
   - `{{ .Data.full_name }}` - User's full name (optional)
   - `{{ .Data.role }}` - User's role (parent/child) (optional)

4. Click **Save**

---

### Step 4: Email Confirmation Settings

1. Go to: **Supabase Dashboard** → **Authentication** → **Settings**

2. Find **Email confirmations** section:
   - ✅ **Enable email confirmations:** ON (for production)
   - ⏰ **Email confirmation expiry:** 24 hours (default is good)

3. Click **Save**

**For Development/Testing:**
- Turn OFF "Enable email confirmations" to auto-confirm all signups
- This lets you test without checking email every time
- **Remember to turn it back ON before App Store submission!**

---

## 📧 Email Template Quick Setup

Use the template at `/ENVIVE_EMAIL_TEMPLATE.html` which includes:

- ✅ Envive branding with purple gradient
- ✅ Welcome message
- ✅ Confirmation button with `{{ .ConfirmationURL }}`
- ✅ Security notice (24-hour expiration)
- ✅ Link fallback for email clients
- ✅ Footer with Privacy Policy and Terms links
- ✅ Mobile-responsive design

**To use it:**
1. Open `ENVIVE_EMAIL_TEMPLATE.html`
2. Copy the entire HTML
3. Paste into Supabase → Email Templates → Confirm signup
4. Save

---

## 🧪 Testing the Email Confirmation Flow

### Test Signup Flow:

1. **Sign up with a real email** (use your own email for testing)
2. **Check your inbox** for confirmation email
3. **Click the confirmation link** in the email
4. **Your app should open** automatically (deep link)
5. **Session should be established** and onboarding continues

### Expected Console Output:

```
📧 Creating new user account: test@example.com
✅ User account created - confirmation email sent to: test@example.com
(User checks email and clicks link)
🔐 Auth callback received
Processing auth callback...
✅ Auth session established with tokens
✅ Email confirmed! Session established
✅ User profile loaded: test@example.com
✅ Email confirmation complete - continuing onboarding
```

---

## ⚠️ Troubleshooting

### Problem: "Email not sent"

**Check:**
1. Supabase → Settings → Auth → SMTP Settings
2. Make sure SMTP is configured (or use Supabase's default email service)
3. Check Supabase logs for email errors

### Problem: "Link doesn't open app"

**Check:**
1. URL scheme is registered: `envivenew://` in Info.plist
2. Redirect URLs are added to Supabase
3. Test the deep link manually: `xcrun simctl openurl booted "envivenew://auth/callback#access_token=test"`

### Problem: "Session not established"

**Check:**
1. Console logs for errors
2. Tokens are being extracted from URL fragment
3. `setSession()` is being called successfully

### Problem: "User can't sign in after confirming email"

**Cause:** Email is confirmed but user hasn't signed in yet

**Solution:** After email confirmation, redirect user to sign-in screen or auto-sign them in (already implemented in your callback handler)

---

## 🔒 Security Notes

### Email Confirmation is Required For:

- ✅ **App Store Compliance** - Apple expects email verification
- ✅ **COPPA/VPC Compliance** - Verifies parent email addresses
- ✅ **Security** - Prevents fake signups
- ✅ **Spam Prevention** - Ensures valid email addresses

### Don't Skip Email Confirmation Unless:

- 🧪 You're in development and need faster testing
- 🔧 You have an alternative verification method
- ⚠️ You understand the security risks

---

## 📱 App Store Submission Checklist

Before submitting to App Store:

- [ ] Supabase Site URL set to `envivenew://`
- [ ] Redirect URLs added to Supabase
- [ ] Email template uploaded and tested
- [ ] Email confirmations **ENABLED** in Supabase
- [ ] Test email flow on real device
- [ ] Privacy Policy links work in email template
- [ ] Terms of Service links work in email template
- [ ] Email sent from professional domain (optional but recommended)

---

## 🎯 Email Service Providers (Optional)

Supabase uses a default email service, but for production you may want:

### Option 1: Use Supabase Default (Easiest)
- ✅ No configuration needed
- ✅ Works immediately
- ⚠️ Generic sender address
- ⚠️ Limited daily quota

### Option 2: Configure Custom SMTP (Recommended)
**Settings → Auth → SMTP Settings**

Popular providers:
- **SendGrid** (free tier: 100 emails/day)
- **Mailgun** (free tier: 1000 emails/month)
- **Amazon SES** (cheap, reliable)
- **Postmark** (transactional email specialist)

Benefits:
- ✅ Custom sender domain (noreply@envive.app)
- ✅ Higher email limits
- ✅ Better deliverability
- ✅ Email analytics

---

## 🚀 Quick Start Commands

### Test Deep Link (Simulator):
```bash
xcrun simctl openurl booted "envivenew://auth/callback#access_token=test&refresh_token=test&type=signup"
```

### Test Deep Link (Physical Device):
1. Email yourself a test link
2. Or use Safari and type: `envivenew://auth/callback`

---

## 📋 Summary

**Your app is ready for email confirmation!**

All you need to do is:
1. Configure Supabase Site URL
2. Add Redirect URLs to Supabase
3. Upload email template
4. Enable email confirmations
5. Test the flow

**Total setup time:** 10-15 minutes

---

## 📞 Support

If you encounter issues:
- Check Supabase logs: Dashboard → Logs
- Check Xcode console for error messages
- Verify all URLs match exactly (case-sensitive)
- Test with a real email address (not a temporary/disposable email)

---

**Note:** This configuration is required for App Store approval. Make sure email confirmation is fully working before submitting to TestFlight or App Store review.
