# Custom Shield Configuration Setup Guide

To display your custom shield instead of Apple's default one, you need to add a **Shield Configuration Extension** to your Xcode project.

## Step 1: Add Shield Configuration Extension in Xcode

1. Open your `EnviveNew.xcodeproj` in Xcode
2. Go to **File → New → Target**
3. Search for "Shield Configuration" or select **Shield Configuration Extension**
4. Click **Next**
5. Configure the extension:
   - **Product Name**: `ShieldConfigurationExtension`
   - **Bundle Identifier**: `com.envivenew.ShieldConfigurationExtension`
   - **Team**: Select your development team
   - **Target to be extended**: Select your main app (`EnviveNew`)
6. Click **Finish**
7. When prompted "Activate 'ShieldConfigurationExtension' scheme?", click **Activate**

## Step 2: Replace Extension Code

1. In Xcode, navigate to the new `ShieldConfigurationExtension` folder
2. Replace the content of `ShieldConfigurationExtension.swift` with the code I created at:
   `/Volumes/ReelNeal55/EnviveNew/ShieldConfigurationExtension/ShieldConfigurationExtension.swift`

## Step 3: Update Info.plist

1. Replace the `Info.plist` in the extension with the one I created at:
   `/Volumes/ReelNeal55/EnviveNew/ShieldConfigurationExtension/Info.plist`

## Step 4: Add Required Capabilities

1. Select your main app target (`EnviveNew`)
2. Go to **Signing & Capabilities**
3. Ensure you have:
   - **Family Controls**
   - **App Groups** (with group: `group.com.envivenew.screentime`)

4. Select the `ShieldConfigurationExtension` target
5. Add the same capabilities:
   - **Family Controls**
   - **App Groups** (with the same group ID)

## Step 5: Build and Test

1. Clean your project (**Product → Clean Build Folder**)
2. Build the project (**⌘+B**)
3. Run the app on a physical device (Shield extensions don't work in simulator)
4. Test by blocking an app - you should now see your custom shield

## Troubleshooting

- **Still seeing Apple's default shield?**
  - Make sure you're testing on a physical device
  - Verify the extension is included in the main app bundle
  - Check that both targets have the same App Group ID

- **Extension not loading?**
  - Check the bundle identifier format
  - Ensure the extension's `Info.plist` has the correct extension point identifier
  - Verify code signing is correct

## Alternative: Simple Message Approach

If the extension setup is too complex, we can simplify by:
1. Using basic ManagedSettings shield
2. Showing a custom in-app message when restrictions are applied
3. Adding an "Open Envive" button in your main app's UI

Would you like me to implement this simpler approach instead?