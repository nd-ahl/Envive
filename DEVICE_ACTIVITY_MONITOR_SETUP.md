# Device Activity Monitor Extension Setup

## The Missing Piece

Your shield buttons aren't working because you're missing a **Device Activity Monitor Extension**. The Shield Configuration Extension only handles the appearance and button actions, but you need a Device Activity Monitor Extension to actually trigger the shields and make them work.

## Setup Instructions

### 1. Add Device Activity Monitor Extension Target

1. In Xcode, select your project file
2. Click the **+** button at the bottom of the target list
3. Choose **App Extension** → **Device Activity Monitor Extension**
4. Name: `DeviceActivityMonitorExtension`
5. Bundle Identifier: `com.neal.envivenew.DeviceActivityMonitorExtension`
6. Click **Finish**

### 2. Replace Generated Files

Replace the generated files with the ones I created:

- Replace `DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift` with the file I created
- Replace `DeviceActivityMonitorExtension/Info.plist` with the file I created

### 3. Add Required Frameworks

Add these frameworks to the **Device Activity Monitor Extension** target:
- DeviceActivity.framework
- ManagedSettings.framework
- FamilyControls.framework

### 4. Add App Groups Capability

Both your main app and the Device Activity Monitor Extension need the same App Group:

1. Select the **Device Activity Monitor Extension** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Add: `group.com.neal.envivenew.screentime`

### 5. Update Main App

Remove the Device Activity Monitor code from your main app since it should be in the extension:

In `EnviveNewDeviceActivityMonitor.swift`, you can simplify it to just handle the helper functions but move the actual monitoring to the extension.

## Why This Fixes the Shield Buttons

- **Device Activity Monitor Extension**: Triggers shields when time limits are reached
- **Shield Configuration Extension**: Provides custom appearance and button handling
- Both extensions work together to create the complete experience

Without the Device Activity Monitor Extension, your shields never get triggered, so the custom shield configuration never appears.

## Testing

After adding the Device Activity Monitor Extension:

1. Build and run the app
2. Set up screen time restrictions
3. Try to access a blocked app
4. You should now see your custom shield with working buttons

The "Open Envive" button will now properly open your app, and "Go to Home Screen" will dismiss the shield.