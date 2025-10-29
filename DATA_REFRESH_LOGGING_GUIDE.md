# Data Refresh Logging Guide

## Overview
This guide shows what logs to look for when testing the automatic data refresh on app launch and background return.

## Expected Log Flow on App Launch

### 1. MainAppWithRefresh Initialization
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏗️ MainAppWithRefresh.init() CALLED
   - showSplashScreen initial value: false
   - authService.isAuthenticated: true/false
   - authService.currentProfile exists: true/false
   - Profile: [Name] ([ID])
   - Household ID: [ID]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. MainAppWithRefresh Body Rendering
```
🏠 MainAppWithRefresh.body rendering - showSplashScreen: false
```

### 3. MainAppWithRefresh onAppear
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 MainAppWithRefresh.onAppear() TRIGGERED
   - Current showSplashScreen value: false
   - authService.isAuthenticated: true
   - authService.currentProfile exists: true
   - User: [Name]
   - Household ID: [ID]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SETTING showSplashScreen = true (UNCONDITIONAL)
   - showSplashScreen is now: true
```

### 4. AnimatedSplashScreen Rendering
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎬 RENDERING AnimatedSplashScreen (showSplashScreen = true)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5. AnimatedSplashScreen Initialization
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎬 AnimatedSplashScreen.init() CALLED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 6. AnimatedSplashScreen onAppear
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎬 AnimatedSplashScreen.onAppear() CALLED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 7. Data Refresh Starts
```
🎬🎬🎬 AnimatedSplashScreen.startDataRefresh() CALLED
🔄🔄🔄 AnimatedSplashScreen: Starting full data refresh...
📞 AnimatedSplashScreen: Calling HouseholdService.refreshAllData()...
```

### 8. HouseholdService.refreshAllData() Execution
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄🔄🔄 HouseholdService.refreshAllData() STARTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 STEP 0: Checking authentication...
   - AuthenticationService.shared exists: ✅
   - authService.isAuthenticated: true
   - authService.currentProfile exists: true
✅ STEP 0 Complete: User authenticated
   - User: [Name]
   - ID: [UUID]
   - Email: [Email]
   - Role: parent
   - Household ID: [UUID]

📋 STEP 1: Checking household ID...
✅ STEP 1 Complete: Household ID found: [UUID]

📋 STEP 2: Fetching household from Supabase...
   - Query: SELECT * FROM households WHERE id = '[UUID]'
✅ STEP 2 Complete: Household loaded
   - Name: [Household Name]
   - ID: [UUID]
   - Invite Code: [Code]
   - Created By: [UUID]

📋 STEP 3: Fetching household members from Supabase...
   - Query: SELECT * FROM profiles WHERE household_id = '[UUID]' ORDER BY role DESC
✅ STEP 3 Complete: Household members loaded
   - Total members: [Count]
   - Member 1: [Name] (parent)
   - Member 2: [Name] (child)

📋 STEP 4: Fetching children profiles...
   - Calling getMyChildren()...
✅ STEP 4 Complete: Children profiles loaded
   - Total children: [Count]
   - Child 1: [Name], Age: [Age], ID: [UUID]

📋 STEP 5: Posting dashboard refresh notification...
✅ STEP 5 Complete: Dashboard refresh notification posted

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅✅✅ HouseholdService.refreshAllData() COMPLETED
   - Total duration: [X.XX]s
   - All data successfully refreshed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 9. Splash Screen Completion
```
✅✅✅ AnimatedSplashScreen: Data refresh completed in [X.XX]s
⏱️ AnimatedSplashScreen: Waiting [X.XX]s for minimum display time
🎉 AnimatedSplashScreen: Transitioning to main app

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔚 AnimatedSplashScreen onComplete callback FIRED
   - About to set showSplashScreen = false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ showSplashScreen set to false - main app should now be visible

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👋 AnimatedSplashScreen.onDisappear() CALLED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Expected Log Flow on Background Return

### 1. Scene Phase Change
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 MainAppWithRefresh scenePhase CHANGED
   - Old phase: ScenePhase.inactive (or background)
   - New phase: ScenePhase.active
   - Current showSplashScreen: false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ App became ACTIVE (from background)
✅ SETTING showSplashScreen = true (UNCONDITIONAL)
   - showSplashScreen is now: true
```

### 2. Splash Screen Shows Again
(Same flow as steps 4-9 from app launch)

## Critical Failure Points to Watch For

### ❌ No Current Profile
```
❌❌❌ CRITICAL: No currentProfile found!
   - Cannot refresh data without authenticated user
   - This is likely why data is not refreshing
```
**Fix**: Ensure AuthenticationService loads the profile on app startup

### ❌ No Household ID
```
⚠️⚠️⚠️ WARNING: User has no household_id
   - Cannot fetch household data
   - User may need to complete onboarding
```
**Fix**: Ensure user completes family setup in onboarding

### ❌ Supabase Query Failure
```
❌❌❌ STEP 2 FAILED: Could not fetch household
   - Error: [Error message]
   - Details: [Full error]
```
**Fix**: Check network connection, Supabase credentials, database tables

### ❌ Splash Screen Not Rendering
```
⚠️ NOT showing splash screen (showSplashScreen = false)
```
**Fix**: Check if MainAppWithRefresh.onAppear is firing and setting showSplashScreen = true

## Testing Instructions

1. **Test App Launch**:
   - Kill the app completely
   - Launch the app
   - Watch Xcode console for the full log flow above
   - Verify all steps complete successfully

2. **Test Background Return**:
   - With app running, press Home button (or Cmd+Shift+H in simulator)
   - Wait 5 seconds
   - Reopen the app
   - Watch console for scene phase change and data refresh

3. **Success Criteria**:
   - All ✅ marks appear in logs
   - No ❌ errors appear
   - Splash screen shows for ~1.5 seconds
   - Parent dashboard shows fresh data (no manual refresh needed)

## Common Issues and Solutions

### Issue: Splash screen doesn't appear
**Check**: MainAppWithRefresh.onAppear logs show "SETTING showSplashScreen = true"
**Solution**: Ensure MainAppWithRefresh is being rendered in the view hierarchy

### Issue: Data refresh doesn't start
**Check**: AnimatedSplashScreen.onAppear logs
**Solution**: Ensure AnimatedSplashScreen is being created and onAppear is firing

### Issue: "No currentProfile" error
**Check**: AuthenticationService.currentProfile at app startup
**Solution**: Add profile loading in app initialization or scene phase change

### Issue: Data loads but UI doesn't update
**Check**: Dashboard refresh notification is posted (STEP 5)
**Solution**: Ensure ParentDashboardView subscribes to notification or observes HouseholdService properties
