# 📱 Envive App Store Submission Checklist

**Last Updated:** 2025-10-30
**App Version:** 1.0
**Target Release:** TBD

---

## 🔴 CRITICAL BLOCKERS (Must Fix Before Any Testing)

### BUILD & COMPILATION
- [ ] **Fix swift-clocks dependency issue**
  - Error: `no such module 'ConcurrencyExtras'`
  - Action: Reset package caches, resolve dependencies
  - Verification: `xcodebuild -project EnviveNew.xcodeproj -target EnviveNew build` succeeds
  - Status: ❌ BLOCKING

- [ ] **Successful Release Build**
  - Archive builds without errors
  - All targets compile (main app + extensions)
  - No compiler warnings in critical code
  - Status: ❌ PENDING

---

## 🐛 CRITICAL BUGS (Must Fix Before Submission)

### Core Functionality Bugs
- [ ] **Screen Time XP Persistence Bug**
  - Location: `ContentView.swift:7256`, `ContentView.swift:2229-2232`
  - Issue: XP restored on app restart, giving infinite screen time
  - Fix Applied: Added `model.childId = childId` assignment, validation checks
  - Test Steps:
    1. Child earns 30 XP (30 minutes)
    2. Start 30-minute screen time session
    3. Wait for 2 full minutes to elapse
    4. Force quit app (background → swipe up)
    5. Reopen app
    6. **VERIFY:** Child has 28 XP (not 30) ✅
  - Console verification: Check for "✅ Minute elapsed - deducted 1 XP" logs
  - Error verification: Should NOT see "❌ CRITICAL BUG: childId is NIL" logs
  - Status: ⚠️ FIXED, NEEDS TESTING

---

## 🏗️ TECHNICAL REQUIREMENTS

### Build Configuration
- [ ] **Deployment Target**
  - iOS 17.0+ (required for Family Controls)
  - All targets use same deployment version
  - Status: ⏳ VERIFY

- [ ] **Signing & Provisioning**
  - Valid App Store distribution certificate
  - App ID registered in Apple Developer Portal
  - App Store provisioning profile configured
  - Status: ⏳ VERIFY

- [ ] **App Identifier**
  - Unique bundle identifier (e.g., `com.envivenew.app`)
  - Matches App Store Connect
  - Status: ⏳ VERIFY

- [ ] **Version & Build Numbers**
  - Version number set (e.g., 1.0.0)
  - Build number incremented
  - All targets have matching version
  - Status: ⏳ VERIFY

### Required Capabilities & Entitlements
- [ ] **Family Controls Entitlement**
  - Entitlement: `com.apple.developer.family-controls`
  - Required for Screen Time API
  - Request approval from Apple
  - Status: ⏳ VERIFY

- [ ] **App Groups** (if using)
  - Configured for data sharing between extensions
  - Status: ⏳ VERIFY

- [ ] **Background Modes** (if needed)
  - Only essential background modes enabled
  - Status: ⏳ VERIFY

### Extensions Configuration
- [ ] **ShieldConfigurationExtension**
  - Builds and embeds correctly
  - Shows custom UI when apps are blocked
  - Status: ⏳ VERIFY

- [ ] **DeviceActivityMonitorExtension**
  - Builds and embeds correctly
  - Monitors screen time correctly
  - Status: ⏳ VERIFY

- [ ] **EnviveNewWidgetsExtension**
  - Builds and embeds correctly
  - Widget displays correctly
  - Status: ⏳ VERIFY

---

## 📄 LEGAL & PRIVACY COMPLIANCE

### Privacy Policy & Terms
- [ ] **Privacy Policy URL**
  - URL: `https://nd-ahl.github.io/Envive/privacy-policy`
  - Status: ⏳ VERIFY URL IS LIVE
  - Content covers:
    - [ ] What data is collected
    - [ ] How data is used
    - [ ] How data is stored (Supabase)
    - [ ] User rights (access, deletion)
    - [ ] Children's privacy (COPPA)
    - [ ] Family Controls usage
    - [ ] Camera/photo usage
    - [ ] Contact information

- [ ] **Terms of Service URL**
  - URL: `https://nd-ahl.github.io/Envive/terms-of-service`
  - Status: ⏳ VERIFY URL IS LIVE
  - Content covers:
    - [ ] User responsibilities
    - [ ] Account terms
    - [ ] Subscription terms (if applicable)
    - [ ] Termination policy
    - [ ] Liability limitations

### Info.plist Privacy Descriptions
- [x] **NSFaceIDUsageDescription**
  - Text: "Envive uses Face ID to securely authenticate parents when managing app restrictions and changing screen time passwords."
  - Status: ✅ PRESENT

- [x] **NSFamilyControlsUsageDescription**
  - Text: "Envive uses Screen Time controls to help parents manage their children's app usage and screen time limits."
  - Status: ✅ PRESENT

- [x] **NSCameraUsageDescription**
  - Text: "Envive uses the camera to capture verification photos for completed tasks and activities."
  - Status: ✅ PRESENT

- [x] **NSPhotoLibraryUsageDescription**
  - Text: "Envive needs access to save captured task verification photos to your photo library and to select photos for your profile."
  - Status: ✅ PRESENT

- [x] **NSPhotoLibraryAddUsageDescription**
  - Text: "Envive needs access to save photos to your library."
  - Status: ✅ PRESENT

### Data Collection & Privacy Nutrition Labels
- [ ] **Data Used to Track You**
  - List any tracking data
  - Status: ⏳ COMPLETE IN APP STORE CONNECT

- [ ] **Data Linked to User**
  - Account info (email, name)
  - Child profiles (name, age)
  - Task completion data
  - XP/credibility scores
  - Screen time usage
  - Profile photos
  - Status: ⏳ COMPLETE IN APP STORE CONNECT

- [ ] **Data Not Linked to User**
  - Analytics (if any)
  - Status: ⏳ COMPLETE IN APP STORE CONNECT

### Children's Privacy (COPPA Compliance)
- [ ] **Parental Consent Mechanism**
  - Parents must create account first
  - Parents add children to household
  - Children under 13 require parental consent
  - Status: ⏳ VERIFY

- [ ] **Age Verification**
  - App collects child age during setup
  - Appropriate restrictions for under 13
  - Status: ⏳ VERIFY

- [ ] **Data Minimization**
  - Only collect essential child data
  - No advertising to children
  - No child data sold or shared
  - Status: ⏳ VERIFY

---

## 🎨 APP STORE ASSETS

### App Icons
- [ ] **AppIcon.appiconset Complete**
  - 1024x1024 App Store icon (required)
  - All required iOS icon sizes
  - No transparency
  - No rounded corners (iOS adds them)
  - Location: `/EnviveNew/Assets.xcassets/AppIcon.appiconset/`
  - Status: ⏳ VERIFY ALL SIZES PRESENT

### Screenshots
- [ ] **6.7" Display (iPhone 15 Pro Max, 14 Pro Max)**
  - At least 3 screenshots (up to 10)
  - 1290 x 2796 pixels
  - Status: ❌ NEEDED

- [ ] **6.5" Display (iPhone 11 Pro Max, XS Max)**
  - At least 3 screenshots (up to 10)
  - 1284 x 2778 pixels
  - Status: ❌ NEEDED

- [ ] **5.5" Display (iPhone 8 Plus, 7 Plus)**
  - At least 3 screenshots (up to 10)
  - 1242 x 2208 pixels
  - Status: ❌ NEEDED

### Screenshot Content Requirements
- [ ] **Showcase Key Features**
  - Parent dashboard
  - Child task view
  - Screen time management
  - XP/credibility system
  - App restrictions interface
  - Status: ❌ NEEDED

- [ ] **Screenshot Best Practices**
  - High quality, clear interface
  - No placeholder text
  - Representative of actual app
  - No personal information visible
  - Status: ❌ NEEDED

### Preview Video (Optional but Recommended)
- [ ] **App Preview Video**
  - 15-30 seconds
  - Shows core functionality
  - Vertical orientation
  - Status: ⏳ OPTIONAL

---

## 📝 APP STORE CONNECT METADATA

### Basic Information
- [ ] **App Name**
  - Name: "Envive"
  - Max 30 characters
  - Must be unique on App Store
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Subtitle**
  - Max 30 characters
  - Example: "Family Screen Time Manager"
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Description**
  - Clear explanation of app purpose
  - Key features listed
  - Target audience (families)
  - Max 4000 characters
  - Status: ⏳ WRITE DESCRIPTION

- [ ] **Keywords**
  - Comma-separated
  - Max 100 characters
  - Suggested: "screen time, parental controls, family, kids, tasks, rewards, XP, chores"
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Primary Category**
  - Suggested: Productivity
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Secondary Category**
  - Suggested: Lifestyle or Education
  - Status: ⏳ SET IN APP STORE CONNECT

### Support & Marketing URLs
- [ ] **Support URL** (Required)
  - Working email or contact form
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Marketing URL** (Optional)
  - Product website
  - Status: ⏳ SET IN APP STORE CONNECT

### Contact Information
- [ ] **First Name**
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Last Name**
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Phone Number**
  - Status: ⏳ SET IN APP STORE CONNECT

- [ ] **Email Address**
  - Must be monitored
  - Status: ⏳ SET IN APP STORE CONNECT

### Age Rating
- [ ] **Apple Age Rating Questionnaire**
  - Likely rating: 4+ (suitable for all ages)
  - Review all content categories
  - Status: ⏳ COMPLETE IN APP STORE CONNECT

---

## 🧪 FUNCTIONAL TESTING

### Core Features Testing

#### Parent Features
- [ ] **Parent Account Creation**
  - Email/password signup works
  - Profile creation successful
  - Household automatically created
  - Status: ⏳ TEST

- [ ] **Family Controls Authorization**
  - Authorization prompt appears
  - Parent can grant permission
  - Settings link works if denied
  - Status: ⏳ TEST

- [ ] **App Restriction Management**
  - Parent can select apps to block
  - Block/unblock functionality works
  - Changes take effect immediately
  - Blocked apps show shield screen
  - Status: ⏳ TEST

- [ ] **Child Management**
  - Add new child profile
  - Edit child profile
  - View child's XP/credibility
  - View child's task history
  - Status: ⏳ TEST

- [ ] **Task Creation & Management**
  - Create new task
  - Edit existing task
  - Delete task
  - Assign task to child
  - Review completed tasks
  - Approve/reject task completion
  - Status: ⏳ TEST

- [ ] **Password Management**
  - Set app restriction password
  - Change password with Face ID
  - Change password with current password
  - Forgot password with Face ID works
  - Password syncs across devices
  - Status: ⏳ TEST

- [ ] **Household Invite System**
  - Invite code displayed correctly
  - Copy invite code works
  - Share invite code works
  - Status: ⏳ TEST

#### Child Features
- [ ] **Child Profile Setup**
  - Join household with invite code
  - Profile creation for child
  - Age verification
  - Status: ⏳ TEST

- [ ] **Task Viewing & Completion**
  - View available tasks
  - Mark task as complete
  - Upload photo verification (if required)
  - See pending approval status
  - Receive XP when approved
  - Status: ⏳ TEST

- [ ] **XP & Credibility System**
  - XP earned from approved tasks
  - Credibility score calculated correctly
  - Credibility affects XP earned (multiplier)
  - XP balance displayed correctly
  - Status: ⏳ TEST

- [ ] **Screen Time Redemption**
  - Child can see available minutes (1 XP = 1 minute)
  - Start screen time session
  - Timer counts down correctly
  - Apps become unblocked during session
  - XP deducted per minute used
  - **CRITICAL:** XP deduction persists after app restart
  - Apps re-block when session ends
  - Status: ⏳ TEST

- [ ] **App Management View**
  - Password prompt appears
  - Face ID/Touch ID authentication works
  - Password fallback works
  - View blocked apps list
  - Status: ⏳ TEST

#### Cross-Device Sync
- [ ] **Data Synchronization**
  - Household data syncs via Supabase
  - Task updates sync in real-time
  - XP changes sync across devices
  - Password changes sync across devices
  - Profile changes sync across devices
  - Status: ⏳ TEST

#### Authentication & Security
- [ ] **Biometric Authentication**
  - Face ID prompt appears on supported devices
  - Touch ID prompt appears on supported devices
  - Authentication success grants access
  - Authentication failure shows error
  - Fallback to password works
  - "Use Password Instead" button works
  - Status: ⏳ TEST

- [ ] **Session Management**
  - Parent session stays active appropriately
  - Session timeout works (if implemented)
  - Re-authentication required after timeout
  - Status: ⏳ TEST

### Device Mode Testing
- [ ] **Parent Mode**
  - Correct tabs visible
  - All parent features accessible
  - Status: ⏳ TEST

- [ ] **Child Mode**
  - Correct tabs visible
  - Parent features properly restricted
  - Password protection works
  - Status: ⏳ TEST

- [ ] **Mode Switching** (if applicable)
  - Switch from parent to child mode
  - Switch from child to parent mode
  - Data isolation maintained
  - Status: ⏳ TEST

### Widget Testing
- [ ] **Home Screen Widget**
  - Widget displays correctly
  - Data updates appropriately
  - Tapping widget opens app correctly
  - Status: ⏳ TEST

### Edge Cases & Error Handling
- [ ] **Network Connectivity**
  - App handles offline mode gracefully
  - Syncs when connection restored
  - Error messages are user-friendly
  - Status: ⏳ TEST

- [ ] **Invalid Data**
  - Form validation works
  - Error messages clear and helpful
  - App doesn't crash on invalid input
  - Status: ⏳ TEST

- [ ] **Permission Denials**
  - Camera permission denied: graceful handling
  - Photos permission denied: graceful handling
  - Face ID not available: password fallback works
  - Family Controls denied: proper guidance
  - Status: ⏳ TEST

- [ ] **Low Battery**
  - App functions correctly
  - No excessive battery drain
  - Status: ⏳ TEST

- [ ] **Memory Pressure**
  - App doesn't crash under memory pressure
  - Large photo uploads handled
  - Status: ⏳ TEST

---

## 📱 DEVICE COMPATIBILITY TESTING

### Required Devices
- [ ] **iPhone 15 Pro Max** (or newest available)
  - All features work
  - UI renders correctly
  - Performance acceptable
  - Status: ⏳ TEST

- [ ] **iPhone SE** (smaller screen)
  - UI adapts to smaller screen
  - All features accessible
  - Text readable
  - Status: ⏳ TEST

- [ ] **iPad** (if iPad support claimed)
  - UI scales appropriately
  - All features work
  - Status: ⏳ TEST / N/A

### iOS Versions
- [ ] **Latest iOS** (iOS 18.x)
  - Full compatibility
  - Status: ⏳ TEST

- [ ] **Minimum iOS** (iOS 17.0)
  - All features work on minimum version
  - Status: ⏳ TEST

### Device Features
- [ ] **Face ID Devices**
  - Face ID authentication works
  - Status: ⏳ TEST

- [ ] **Touch ID Devices**
  - Touch ID authentication works
  - Status: ⏳ TEST

- [ ] **No Biometrics Devices**
  - Password fallback works
  - Appropriate messaging
  - Status: ⏳ TEST

---

## 🔍 APPLE REVIEW GUIDELINES COMPLIANCE

### 2.1 App Completeness
- [ ] **No Placeholder Content**
  - No "Coming Soon" or "TODO" visible to users
  - All features described work fully
  - Status: ⏳ VERIFY

- [ ] **No Crashes**
  - App doesn't crash on launch
  - App doesn't crash during normal use
  - Extensive testing completed
  - Status: ⏳ VERIFY

- [ ] **Bug-Free Experience**
  - No major bugs present
  - UI renders correctly on all screens
  - All buttons/actions work
  - Status: ⏳ VERIFY

### 2.3 Accurate Metadata
- [ ] **Screenshots Match App**
  - Screenshots show actual app interface
  - No mockups or concept designs
  - Status: ⏳ VERIFY

- [ ] **Description Matches Functionality**
  - All features described are present
  - No misleading claims
  - Status: ⏳ VERIFY

### 2.5 Software Requirements
- [ ] **iOS SDK Compliance**
  - App uses latest SDK features appropriately
  - Deprecated APIs avoided
  - Status: ⏳ VERIFY

- [ ] **No Private APIs**
  - Only public Apple APIs used
  - Status: ⏳ VERIFY

### 3.1 Payments (if applicable)
- [ ] **In-App Purchases** (if monetized)
  - Uses StoreKit correctly
  - Status: ⏳ N/A or VERIFY

- [ ] **Subscriptions** (if applicable)
  - Clear terms and pricing
  - Easy to cancel
  - Status: ⏳ N/A or VERIFY

### 4.0 Design
- [ ] **Human Interface Guidelines**
  - Follows iOS design patterns
  - Native UI elements used appropriately
  - Status: ⏳ VERIFY

- [ ] **Responsive Design**
  - Adapts to different screen sizes
  - Supports both portrait and landscape (if applicable)
  - Status: ⏳ VERIFY

### 5.1 Privacy
- [ ] **Privacy Policy Link**
  - Accessible before account creation
  - Clearly linked in app and App Store
  - Status: ⏳ VERIFY

- [ ] **Data Collection Disclosure**
  - Users informed of data collection
  - Consent obtained where required
  - Status: ⏳ VERIFY

- [ ] **Children's Data** (CRITICAL for family app)
  - Parental consent required for under 13
  - Minimal data collection from children
  - COPPA compliant
  - Status: ⏳ VERIFY

### 5.1.2 Family Controls
- [ ] **Appropriate Use of Screen Time API**
  - Used only for parental control purposes
  - Not used for advertising/analytics
  - Clear benefit to families
  - Status: ⏳ VERIFY

- [ ] **User Control**
  - Parents fully control restrictions
  - Easy to modify or disable
  - Status: ⏳ VERIFY

---

## 🚀 PRE-SUBMISSION FINAL CHECKS

### Code Quality
- [ ] **Remove Debug Code**
  - No excessive print statements in production
  - Test code commented out or removed
  - Status: ⏳ VERIFY

- [ ] **Remove Test Data**
  - No hardcoded test accounts
  - No dummy data in production build
  - Status: ⏳ VERIFY

- [ ] **Clean Build**
  - No warnings in release build
  - All TODO comments addressed
  - Status: ⏳ VERIFY

### Build & Archive
- [ ] **Archive for Distribution**
  - Product → Archive succeeds
  - No errors in archive process
  - Status: ❌ PENDING

- [ ] **Validate Archive**
  - Xcode validation passes
  - No issues reported
  - Status: ❌ PENDING

- [ ] **Upload to App Store Connect**
  - Upload completes successfully
  - Build appears in App Store Connect
  - Processing completes
  - Status: ❌ PENDING

### Final Testing
- [ ] **TestFlight Internal Testing**
  - Upload to TestFlight
  - Install on fresh device
  - Complete full user journey
  - Status: ❌ PENDING

- [ ] **TestFlight External Testing** (Optional)
  - Invite beta testers
  - Collect feedback
  - Fix critical issues
  - Status: ⏳ OPTIONAL

### Review Preparation
- [ ] **Demo Account** (if app requires login)
  - Provide working demo credentials
  - Account has sample data
  - Status: ⏳ PROVIDE TO APPLE

- [ ] **Review Notes**
  - Explain Family Controls usage
  - Provide test instructions
  - Note any special setup requirements
  - Status: ⏳ WRITE FOR APPLE

- [ ] **Contact Information**
  - Phone number provided
  - Email monitored
  - Available to respond to Apple
  - Status: ⏳ VERIFY

---

## 📊 TESTING PRIORITY LEVELS

### P0 - Critical (Must Pass Before Submission)
- Build succeeds
- No crashes on launch
- Core screen time functionality works
- XP persistence bug fixed and verified
- Parent can manage restrictions
- Child can complete tasks and earn XP
- Authentication works (password + biometrics)

### P1 - High Priority (Should Pass Before Submission)
- All device sizes tested
- Network error handling
- Permission denials handled gracefully
- Data syncs across devices
- Privacy URLs work and content accurate

### P2 - Medium Priority (Nice to Have)
- Widget works perfectly
- Edge cases handled
- Performance optimized
- UI polish complete

---

## 📝 NOTES SECTION

### Known Issues
- Document any known non-critical bugs
- Plan for future fixes

### Deferred Features
- Features planned for v1.1+
- Not blocking release

### Apple Review Feedback
- Document any feedback from Apple
- Track resolution of issues

---

## ✅ FINAL SUBMISSION CHECKLIST

**Only check these when EVERYTHING above is complete:**

- [ ] All critical blockers resolved
- [ ] All P0 tests passing
- [ ] Build uploaded to App Store Connect
- [ ] All metadata complete in App Store Connect
- [ ] Screenshots uploaded
- [ ] Privacy policy live and accurate
- [ ] Age rating complete
- [ ] Pricing set (free or paid)
- [ ] Territories selected
- [ ] Demo account provided (if needed)
- [ ] Review notes written
- [ ] **SUBMIT FOR REVIEW button pressed**

---

## 📅 VERSION HISTORY

### v1.0.0 - Initial Release
- Date Submitted: TBD
- Status: In Progress
- Apple Review Status: Not Submitted

---

## 🆘 RESOURCES

### Apple Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Family Controls Documentation](https://developer.apple.com/documentation/familycontrols)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)

### Internal Documentation
- [XP Persistence Bug Fix](ContentView.swift:7256, 2229-2232)
- [Biometric Authentication Implementation](Services/BiometricAuthenticationService.swift)
- [Password Management](Services/ParentPasswordManager.swift)

---

**END OF CHECKLIST**

*Update this checklist as you progress. Check items off as completed. Add notes for any issues discovered.*
