# Biometric Authentication Splash Screen Fix

## Problem Description

**Issue**: After Face ID/Touch ID verification during password reset, the splash screen would appear and interrupt the flow, sending parents back to the dashboard instead of completing the password change.

**User Impact**: Parents could not successfully change their app restriction password using biometric authentication because the flow was constantly interrupted.

## Root Cause Analysis

### The Race Condition

1. **User Action**: User opens ChangePasswordView and triggers Face ID
2. **Auth Starts**: `BiometricAuthenticationService.authenticateParent()` sets `isAuthenticating = true`
3. **iOS Background**: Face ID UI appears, iOS moves app to `.background` phase
4. **User Authenticates**: User completes Face ID authentication
5. **Auth Completes**: Service sets `isAuthenticating = false` on MainActor
6. **iOS Foreground**: Face ID UI dismisses, iOS moves app back to `.active` phase
7. **Race Condition**: Steps 5 and 6 can occur in either order!

### The Problem

If step 6 (app becomes `.active`) happens before step 5 (`isAuthenticating = false`) completes on MainActor:

```
T+0ms:   Face ID completes, starts updating isAuthenticating to false
T+5ms:   App transitions to .active (Face ID UI dismissed)
T+10ms:  scenePhase onChange fires, checks isAuthenticating
T+15ms:  isAuthenticating is still true (update not completed yet)
T+20ms:  SPLASH SCREEN SHOWN ❌ (incorrectly thinks auth is done)
T+25ms:  isAuthenticating finally becomes false (too late!)
```

Even worse, if iOS is slow to transition back:

```
T+0ms:   Face ID completes
T+1ms:   isAuthenticating set to false ✅
T+100ms: App finally transitions to .active
T+101ms: scenePhase onChange fires, checks isAuthenticating
T+102ms: isAuthenticating is false (already cleared)
T+103ms: SPLASH SCREEN SHOWN ❌ (no protection!)
```

## Solution: Grace Period Protection

### Implementation

Added a **grace period** system that prevents splash screen for 1 second after biometric authentication completes:

```swift
// BiometricAuthenticationService.swift
@Published var isAuthenticating: Bool = false
var authCompletionTime: Date?
private let gracePeriod: TimeInterval = 1.0

var shouldPreventSplashScreen: Bool {
    if isAuthenticating { return true }

    if let completionTime = authCompletionTime {
        let elapsed = Date().timeIntervalSince(completionTime)
        return elapsed < gracePeriod  // Block for 1 second
    }

    return false
}
```

### How It Works

1. **Auth Starts**: Set `isAuthenticating = true`
2. **Auth Completes**: Set `isAuthenticating = false` AND `authCompletionTime = Date()`
3. **App Activation**: Check `shouldPreventSplashScreen` instead of just `isAuthenticating`
4. **Grace Period**: Splash screen blocked for 1 second after auth completes
5. **Auto Clear**: Grace period naturally expires after 1 second
6. **Manual Clear**: Views call `clearGracePeriod()` on dismiss for instant cleanup

### Timeline With Fix

```
T+0ms:   Face ID completes
T+1ms:   isAuthenticating = false
T+1ms:   authCompletionTime = Date() ✅
T+100ms: App transitions to .active
T+101ms: scenePhase onChange fires
T+102ms: Checks shouldPreventSplashScreen
T+103ms: Grace period is 0.102s < 1.0s
T+104ms: SPLASH SCREEN BLOCKED ✅
T+1000ms: User completes password change
T+1001ms: View dismisses, calls clearGracePeriod()
T+1002ms: Protection cleared
```

## Files Modified

### 1. BiometricAuthenticationService.swift

**Added:**
- `authCompletionTime: Date?` - Timestamp when auth completes
- `gracePeriod: TimeInterval = 1.0` - Protection duration
- `shouldPreventSplashScreen: Bool` - Computed property with grace period logic
- `clearGracePeriod()` - Manual cleanup method

**Modified:**
- `authenticateParent()` - Sets `authCompletionTime` after auth (all paths: success, error, failure)

**Lines Changed:** 14-18, 52-71, 119-122, 133-136, 149-151, 171-174

### 2. EnviveNewApp.swift

**Modified:**
- `MainAppWithRefresh.onChange(of: scenePhase)` - Uses `shouldPreventSplashScreen` instead of just `isAuthenticating`
- Added detailed logging for debugging race conditions

**Lines Changed:** 640-665

### 3. ParentPasswordView.swift

**Added:**
- `onDisappear` handler to `ChangePasswordView` - Clears grace period when leaving settings
- `onDisappear` handler to `BiometricPasswordResetView` - Clears grace period after reset

**Lines Changed:** 562-565, 878-881

### 4. PasswordResetOptionsView.swift

**Added:**
- `onDisappear` handler - Clears grace period when user exits without selecting option

**Lines Changed:** 168-171

## Testing Scenarios

### Scenario 1: Fast Face ID
1. Open password settings
2. Trigger Face ID
3. Authenticate quickly (< 100ms)
4. ✅ Should stay in password settings (no splash screen)

### Scenario 2: Slow Face ID
1. Open password settings
2. Trigger Face ID
3. Wait 2-3 seconds before authenticating
4. ✅ Should stay in password settings (no splash screen)

### Scenario 3: Failed Face ID
1. Open password settings
2. Trigger Face ID
3. Fail authentication (wrong face)
4. ✅ Should stay in password settings with error message

### Scenario 4: Cancelled Face ID
1. Open password settings
2. Trigger Face ID
3. Cancel authentication
4. ✅ Should stay in password settings

### Scenario 5: App Backgrounding During Auth
1. Open password settings
2. Trigger Face ID
3. Immediately press home button
4. Return to app
5. ✅ Should not show splash screen (grace period active)

### Scenario 6: Normal App Backgrounding
1. Complete password change successfully
2. Navigate away from settings
3. Put app in background for 5 seconds
4. Return to app
5. ✅ Should show splash screen (grace period cleared)

## Debug Logging

The fix includes extensive logging to diagnose any future issues:

```
🔄 MainAppWithRefresh scenePhase CHANGED
   - Old phase: background
   - New phase: active
   - Current showSplashScreen: false
   - Biometric auth in progress: false
   - Should prevent splash: true
   - Time since auth completed: 0.234s
⏸️ SKIPPING splash screen - biometric auth active or within grace period
```

## Benefits

✅ **Robust**: Handles race conditions and timing variations
✅ **Safe**: Multiple layers of protection (isAuthenticating + grace period)
✅ **Clean**: Auto-expires after 1 second, no lingering effects
✅ **Debuggable**: Extensive logging for troubleshooting
✅ **User-Friendly**: No interruptions during authentication flows
✅ **Performant**: Minimal overhead, simple timestamp checks

## Future Improvements

If needed, the grace period could be made configurable:

```swift
private var gracePeriod: TimeInterval {
    #if DEBUG
    return 2.0  // Longer for debugging
    #else
    return 1.0  // Standard for production
    #endif
}
```

Or context-aware:

```swift
func extendGracePeriod(to duration: TimeInterval) {
    self.gracePeriod = duration
    authCompletionTime = Date()  // Reset timer
}
```

## Related Issues

This fix also prevents splash screen interruptions for:
- ParentPasswordView (unlocking app restrictions)
- Any future biometric authentication flows
- Device passcode authentication (uses same service)

## Verification

To verify the fix is working:

1. Enable debug logging
2. Trigger Face ID in password settings
3. Watch console for "⏸️ SKIPPING splash screen" message
4. Verify "Time since auth completed" is < 1.0s when skip occurs
5. Verify splash screen appears normally when NOT in auth flows
