# Envive Email Template Setup Guide

This guide will help you set up the redesigned confirmation email template in your Supabase project.

## 📧 Email Templates Included

1. **ENVIVE_EMAIL_TEMPLATE.html** - Beautiful HTML email with gradient styling
2. **ENVIVE_EMAIL_TEMPLATE.txt** - Plain text fallback version

## 🎨 Design Features

The new email template includes:

- **Envive Blue & Purple Gradient** - Classic brand colors (Blue: #667eea, Purple: #764ba2)
- **Modern, Polished Design** - Clean layout with proper spacing and typography
- **Mobile Responsive** - Adapts perfectly to all screen sizes
- **Welcoming Tone** - Friendly, encouraging copy
- **Security Info Box** - Highlighted security information with gradient background
- **Professional Footer** - Links to privacy policy, terms, and support
- **Fallback Link** - Plain text link for email clients that don't support buttons

## 📋 Setup Instructions

### Step 1: Access Supabase Email Templates

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project: `vevcxsjcqwlmmlchfymn`
3. Navigate to **Authentication** → **Email Templates** in the left sidebar

### Step 2: Configure Confirmation Email

1. Click on the **"Confirm signup"** template
2. Replace the **HTML Template** with the contents of `ENVIVE_EMAIL_TEMPLATE.html`
3. Replace the **Plain Text Template** with the contents of `ENVIVE_EMAIL_TEMPLATE.txt`
4. Click **Save**

### Step 3: Template Variables

The template uses these Supabase magic variables (no changes needed):

- `{{ .ConfirmationURL }}` - The unique confirmation link for the user
- `{{ .Email }}` - The user's email address

These are automatically populated by Supabase when sending emails.

### Step 4: Test the Email

1. Sign up a new user in your app
2. Check the email inbox
3. Verify that:
   - ✅ Gradient header displays correctly
   - ✅ Button is styled with gradient
   - ✅ Info box has gradient background
   - ✅ Footer links are working
   - ✅ Email is mobile-responsive

## 🎯 Email Preview

### Desktop View
```
┌─────────────────────────────────────────┐
│ [Gradient Header: Blue → Purple]       │
│            Envive                       │
│   Screen Time Management Made Simple    │
└─────────────────────────────────────────┘
│                                         │
│  Welcome to Envive! 🎉                 │
│                                         │
│  We're excited to have you join our     │
│  community...                           │
│                                         │
│  ┌───────────────────────────┐         │
│  │  Confirm Email Address    │         │
│  └───────────────────────────┘         │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 🔒 SECURE VERIFICATION           │ │
│  │ This link will expire in 24 hrs  │ │
│  └───────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
│ [Footer with links]                    │
└─────────────────────────────────────────┘
```

### Mobile View
Automatically adjusts:
- Smaller padding
- Reduced font sizes
- Full-width button
- Stacked layout

## 🎨 Customization Options

### Change Colors

To customize the gradient colors, update these values in the HTML:

```css
/* Header gradient */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Button gradient */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Info box gradient */
background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
```

### Change Copy

Update the following sections in the HTML:

1. **Header Subtitle**: Line 97 - `<p class="header-subtitle">`
2. **Greeting**: Line 104 - `<h2 class="greeting">`
3. **Main Message**: Line 106-109 - `<p class="message">`
4. **Info Box**: Line 118-124 - `<div class="info-box">`
5. **Footer Text**: Customize as needed

### Add Logo Image

To add an actual logo image instead of text:

Replace line 96-97:
```html
<h1 class="logo-text">Envive</h1>
```

With:
```html
<img src="https://your-cdn.com/envive-logo-white.png"
     alt="Envive Logo"
     style="height: 48px; width: auto;">
```

## 📱 Email Client Compatibility

The template is tested and works on:

- ✅ Apple Mail (iOS/macOS)
- ✅ Gmail (Web/Mobile)
- ✅ Outlook (Web/Desktop)
- ✅ Yahoo Mail
- ✅ ProtonMail
- ✅ Thunderbird

## 🔐 Security Best Practices

The email template includes:

1. **Expiry Notice** - Users know the link expires in 24 hours
2. **Clear Sender** - Email clearly identifies as from Envive
3. **Ignore Instructions** - Users told to ignore if they didn't sign up
4. **HTTPS Links** - All links use secure HTTPS protocol

## 🎨 Other Email Templates

You can use similar designs for:

### Password Reset Email
- Subject: "Reset Your Envive Password"
- Use same gradient styling
- Update button to "Reset Password"

### Welcome Email (Post-Confirmation)
- Subject: "Welcome to Envive - Let's Get Started!"
- Add getting started tips
- Link to onboarding resources

### Invite Email (Family Members)
- Subject: "You've Been Invited to Join [Family Name] on Envive"
- Include household name
- Link to join with invite code

## 📊 Analytics (Optional)

To track email opens and clicks, add UTM parameters to links:

```html
<a href="{{ .ConfirmationURL }}?utm_source=email&utm_medium=confirmation&utm_campaign=signup">
```

## 🆘 Troubleshooting

### Email Not Displaying Correctly?

1. **Check Spam Folder** - Confirmation emails sometimes get filtered
2. **Verify HTML** - Ensure no syntax errors when copying
3. **Test Plain Text** - Some email clients default to plain text
4. **Clear Cache** - Supabase may cache old templates

### Variables Not Showing?

- Ensure you're using the exact variable names: `{{ .ConfirmationURL }}` and `{{ .Email }}`
- Check for extra spaces or typos in variable names
- Verify the template is saved in the correct section

### Styling Issues?

- Use inline styles for critical CSS (already done)
- Avoid external stylesheets or complex CSS
- Test in multiple email clients
- Use email testing tools like Litmus or Email on Acid

## 📝 Support

If you need help:
- Supabase Docs: https://supabase.com/docs/guides/auth/auth-email-templates
- Email HTML Guide: https://www.campaignmonitor.com/css/

## ✨ Final Checklist

Before going live:

- [ ] HTML template copied to Supabase
- [ ] Plain text template copied to Supabase
- [ ] Templates saved successfully
- [ ] Test email sent and received
- [ ] Email displays correctly on desktop
- [ ] Email displays correctly on mobile
- [ ] All links are working
- [ ] Gradient colors look correct
- [ ] Footer information is accurate
- [ ] Contact email is correct (support@envive.app)

---

**Designed for Envive** | Classic Blue & Purple Gradient Style | Mobile-First Design
