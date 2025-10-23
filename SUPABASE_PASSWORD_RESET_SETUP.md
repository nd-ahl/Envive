# Supabase Password Reset Configuration Guide

## Quick Setup Checklist

Complete these steps in your Supabase Dashboard to enable password reset emails:

### ✅ Step 1: Configure Email Templates
1. Go to: **Authentication → Email Templates**
2. Select: **Reset Password** template
3. Customize the email content (see template below)
4. Click **Save**

### ✅ Step 2: Set Redirect URL
1. Go to: **Authentication → URL Configuration**
2. Add to **Redirect URLs** list:
   ```
   envive://reset-password-callback
   ```
3. Click **Save**

### ✅ Step 3: Configure Email Settings
1. Go to: **Project Settings → Auth**
2. Under **SMTP Settings**, configure your email provider
3. Test email delivery

---

## Recommended Email Template

### Subject Line
```
Reset Your Envive Password
```

### Email Body (HTML)
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">

  <!-- Header -->
  <div style="text-align: center; padding: 30px 0 20px 0;">
    <h1 style="color: #007AFF; margin: 0; font-size: 28px;">Envive</h1>
    <p style="color: #666; margin: 5px 0 0 0;">Family Screen Time Management</p>
  </div>

  <!-- Main Content -->
  <div style="background: #f8f9fa; border-radius: 12px; padding: 30px; margin: 20px 0;">
    <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">Reset Your Password</h2>

    <p style="margin: 0 0 15px 0;">Hi there,</p>

    <p style="margin: 0 0 15px 0;">
      You requested to reset your password for your Envive family account.
      No worries—it happens to everyone!
    </p>

    <p style="margin: 0 0 25px 0;">
      Click the button below to create a new password:
    </p>

    <!-- Reset Button -->
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .ConfirmationURL }}"
         style="display: inline-block; padding: 16px 32px; background-color: #007AFF;
                color: white; text-decoration: none; border-radius: 12px; font-weight: 600;
                font-size: 16px; box-shadow: 0 4px 12px rgba(0, 122, 255, 0.3);">
        Reset My Password
      </a>
    </div>

    <!-- Alternative Link -->
    <p style="font-size: 14px; color: #666; margin: 20px 0 0 0;">
      Or copy and paste this link into your browser:
    </p>
    <p style="font-size: 14px; color: #007AFF; word-break: break-all; margin: 5px 0 0 0;">
      {{ .ConfirmationURL }}
    </p>
  </div>

  <!-- Security Notice -->
  <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px;">
    <p style="margin: 0; font-size: 14px; color: #856404;">
      <strong>⏰ This link will expire in 24 hours</strong> for security reasons.
    </p>
  </div>

  <!-- Footer -->
  <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
    <p style="font-size: 14px; color: #666; margin: 0 0 10px 0;">
      If you didn't request this password reset, you can safely ignore this email.
      Your password will remain unchanged.
    </p>

    <p style="font-size: 14px; color: #666; margin: 10px 0 0 0;">
      Need help? Contact us at
      <a href="mailto:support@envive.app" style="color: #007AFF; text-decoration: none;">
        support@envive.app
      </a>
    </p>
  </div>

  <!-- Brand Footer -->
  <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
    <p style="font-size: 12px; color: #999; margin: 5px 0;">
      © 2025 Envive. All rights reserved.
    </p>
    <p style="font-size: 12px; color: #999; margin: 5px 0;">
      Turn Chores into Screen Time
    </p>
  </div>

</body>
</html>
```

---

## Testing Your Configuration

### 1. Test Email Delivery
```bash
# Use Supabase CLI or Dashboard to send test email
# Or test through the app:
# 1. Open app → Navigate to Sign In
# 2. Tap "Forgot Password?"
# 3. Enter a real email address you control
# 4. Tap "Send Reset Link"
# 5. Check email inbox (including spam folder)
```

### 2. Verify Email Content
Check that the email:
- [x] Has correct subject line
- [x] Contains reset button/link
- [x] Link opens correctly
- [x] Branding matches your app
- [x] Mobile-responsive design

### 3. Test Reset Flow
1. Click reset link in email
2. Enter new password
3. Submit form
4. Return to app
5. Sign in with new password
6. Verify old password no longer works

---

## Email Provider Configuration

### Option 1: Use Supabase Default (Development)
- No configuration needed
- Uses Supabase's SendGrid account
- Limited to 3 emails per hour per user
- Good for testing, not production

### Option 2: Custom SMTP (Production)

#### SendGrid Setup
```
SMTP Server: smtp.sendgrid.net
Port: 587
Username: apikey
Password: <Your SendGrid API Key>
From: noreply@yourdomain.com
```

#### AWS SES Setup
```
SMTP Server: email-smtp.us-east-1.amazonaws.com
Port: 587
Username: <Your SMTP username>
Password: <Your SMTP password>
From: noreply@yourdomain.com
```

#### Gmail (Development Only)
```
SMTP Server: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: <App-specific password>
From: your-email@gmail.com
```

**Note:** Enable "App Passwords" in Google Account settings

---

## Security Best Practices

### ✅ Implemented
- Token expiration (24 hours default)
- Single-use tokens
- Secure HTTPS links only
- Rate limiting per email address

### 🔒 Recommended Additional Settings

#### 1. Rate Limiting
In Supabase Dashboard → **Auth Settings**:
```
Password reset rate limit: 3 per hour per email
```

#### 2. Email Verification
Require email verification before allowing password reset:
```sql
-- In Supabase SQL Editor
-- Ensure users are verified before reset
ALTER TABLE auth.users
  ADD CONSTRAINT verified_users_only
  CHECK (email_confirmed_at IS NOT NULL);
```

#### 3. Security Notifications
Send notification when password is changed:
- "Your password was recently changed"
- "If you didn't make this change, contact support immediately"

---

## Monitoring & Analytics

### Track in Supabase Dashboard
1. Go to: **Authentication → Logs**
2. Filter by: `password_recovery` events
3. Monitor:
   - Number of reset requests
   - Success/failure rates
   - Email delivery status
   - Token expiration rates

### Add Custom Analytics
```swift
// In handlePasswordReset()
func handlePasswordReset() {
    // ... existing code ...

    // Add analytics tracking
    Analytics.track("password_reset_requested", properties: [
        "email": email,
        "timestamp": Date()
    ])
}
```

---

## Common Issues & Solutions

### Issue: Emails not being delivered
**Solutions:**
1. Check spam/junk folder
2. Verify SMTP credentials
3. Check Supabase logs for delivery errors
4. Verify sender domain is not blacklisted
5. Test with different email providers (Gmail, Outlook, etc.)

### Issue: Reset link says "Invalid Token"
**Solutions:**
1. Token may have expired (24hr default)
2. Token already used (single-use)
3. Request new reset link
4. Check if user's email is verified

### Issue: Reset link doesn't open app
**Solutions:**
1. Verify deep link configuration in Xcode
2. Check URL scheme in Info.plist
3. Test on physical device (simulator may not handle deep links)
4. Verify redirect URL in Supabase matches app's URL scheme

---

## Production Deployment Checklist

Before going live:

- [ ] Custom SMTP configured (not using Supabase default)
- [ ] Email template tested and branded
- [ ] Redirect URLs configured correctly
- [ ] Deep link handler implemented and tested
- [ ] Rate limiting enabled
- [ ] Email analytics/monitoring set up
- [ ] Support contact info added to emails
- [ ] Tested on iOS devices (not just simulator)
- [ ] Verified email deliverability to major providers
- [ ] Security notifications configured
- [ ] FAQ/help documentation created
- [ ] Customer support process documented

---

## Next Steps

1. **Configure Supabase** using steps above
2. **Test the flow** with a real email address
3. **Verify** emails are delivered and formatted correctly
4. **Test deep linking** on a physical iOS device
5. **(Optional)** Implement in-app password reset page
6. **Monitor** usage and email delivery rates
7. **Iterate** on email template based on user feedback

---

## Support

If you encounter issues:
1. Check Supabase documentation: https://supabase.com/docs/guides/auth
2. Review authentication logs in Supabase Dashboard
3. Test with Supabase CLI for detailed error messages
4. Contact Supabase support for email delivery issues

---

**Status:** Configuration required in Supabase Dashboard
**Estimated Setup Time:** 15-30 minutes
**Difficulty:** Easy ⭐️
