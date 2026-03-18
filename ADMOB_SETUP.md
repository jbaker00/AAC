# Google AdMob Integration Guide

This document provides step-by-step instructions for setting up Google AdMob for the AAC Communication app.

## Overview

The app now includes Google AdMob banner ads displayed at the bottom of:
- Main content view (ContentView)
- Settings view (SettingsView)

The integration uses Google Mobile Ads SDK version 11.0.0+ via Swift Package Manager.

## Step 1: Create Google AdMob Account

1. Go to https://admob.google.com/
2. Sign in with your Google account (or create one if needed)
3. Click "Get Started" and follow the onboarding process

## Step 2: Create an App in AdMob

1. In the AdMob console, go to "Apps" in the left sidebar
2. Click "Add App"
3. Select "iOS" as the platform
4. Choose "No" for "Is your app listed on a supported app store?" (or "Yes" if already published)
5. Enter app details:
   - **App name**: My Words - AAC Communication
   - **Platform**: iOS
   - **Bundle ID**: com.jbaker.AAC
6. Click "Add App"
7. **Save the App ID** that is generated (format: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)

## Step 3: Create Banner Ad Unit

1. After creating the app, you'll be prompted to create an ad unit, or go to "Ad units" tab
2. Click "Add Ad Unit"
3. Select "Banner" as the ad format
4. Enter ad unit details:
   - **Ad unit name**: Main Banner (or your preferred name)
   - **Ad format**: Banner (320x50)
   - Keep default settings (Standard banner, automatic refresh)
5. Click "Create Ad Unit"
6. **Save the Ad Unit ID** that is generated (format: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`)

## Step 4: Configure Local Development

### Option A: Using Secrets.plist (Recommended for Local Development)

Create or update `Secrets.plist` in the project root directory:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GroqAPIKey</key>
    <string>YOUR_GROQ_API_KEY</string>
    <key>OpenAIAPIKey</key>
    <string>YOUR_OPENAI_API_KEY</string>
    <key>AdMobAppID</key>
    <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
    <key>AdMobBannerID</key>
    <string>ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ</string>
</dict>
</plist>
```

**Important**: Never commit `Secrets.plist` to version control (it's already in `.gitignore`)

## Step 5: Configure Xcode Cloud CI

Add the AdMob credentials as **secret** environment variables in your Xcode Cloud workflow:

1. In Xcode: Product → Xcode Cloud → Manage Workflows → Edit
2. Go to Environment → Environment Variables
3. Add the following variables (check "Secret" for each):
   - `ADMOB_APP_ID` = `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`
   - `ADMOB_BANNER_ID` = `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`

## Step 6: Regenerate Xcode Project

After configuring your credentials, regenerate the Xcode project to include the Google Mobile Ads SDK:

```bash
xcodegen generate
```

Then open `AAC.xcodeproj` in Xcode and build the project.

## Testing with Test IDs

During development, you should use Google's **test ad unit IDs** to avoid policy violations:

- **Test App ID**: `ca-app-pub-3940256099942544~1458002511`
- **Test Banner Ad Unit ID**: `ca-app-pub-3940256099942544/2934735716`

The app automatically falls back to these test IDs if production IDs are not configured in `Secrets.plist` or environment variables.

### Important Testing Guidelines

1. **Always use test ads during development**
   - Never click on your own live ads
   - Google may suspend your AdMob account for invalid activity

2. **Test different scenarios**:
   - Launch the app and verify banner appears at bottom
   - Navigate to Settings and verify banner appears there too
   - Check console logs for ad loading status
   - Test on both iPhone and iPad simulators/devices
   - Test with and without network connectivity

3. **Console Log Messages**:
   - ✅ "AdMob banner ad loaded successfully" = Ad loaded
   - ⚠️ "AdMob banner ad failed to load" = Check network or credentials

## Going to Production

When ready to release the app:

1. **Update production credentials**:
   - Add your real AdMob App ID and Banner ID to `Secrets.plist`
   - Update Xcode Cloud environment variables with production IDs

2. **Update Info.plist** (if using a different App ID):
   - The `GADApplicationIdentifier` is set via environment variable
   - Build script will inject the correct value

3. **App Store Compliance**:
   - Ensure you have proper privacy policy that mentions ads
   - Configure App Tracking Transparency (ATT) if needed
   - Update App Store listing to mention ads

## Architecture

### Files Modified/Added:

1. **project.yml**
   - Added Google Mobile Ads SDK dependency via Swift Package Manager

2. **AAC/Info.plist**
   - Added `GADApplicationIdentifier` key (populated from environment)
   - Added `SKAdNetworkItems` array with ad network identifiers

3. **scripts/generate_secrets.sh**
   - Extended to load AdMob credentials from Secrets.plist or environment
   - Generates `Secrets.adMobAppID` and `Secrets.adMobBannerID`
   - Falls back to test IDs if credentials not found

4. **AAC/AACApp.swift**
   - Imports GoogleMobileAds
   - Initializes Google Mobile Ads SDK on app launch

5. **AAC/Views/AdMobBannerView.swift** (NEW)
   - SwiftUI wrapper for GADBannerView
   - Handles ad loading, delegate callbacks, and error reporting
   - Provides `AdBannerContainer` for easy integration

6. **AAC/Views/ContentView.swift**
   - Wrapped content in VStack
   - Added `AdBannerContainer()` at bottom

7. **AAC/Views/SettingsView.swift**
   - Wrapped Form in VStack
   - Added `AdBannerContainer()` at bottom

## Troubleshooting

### Ad not showing

1. Check console logs for error messages
2. Verify credentials in `Secrets.plist` are correct
3. Ensure you ran `xcodegen generate` after adding credentials
4. Try using test ad IDs first
5. Check network connectivity

### Build errors

1. Run `xcodegen generate` to regenerate the project
2. Clean build folder (Cmd+Shift+K in Xcode)
3. Rebuild the project
4. Ensure Google Mobile Ads SDK was downloaded by SPM

### Production ads not serving

1. New ad units can take a few hours to start serving ads
2. Ensure App ID matches the one in AdMob console
3. Check AdMob console for account status
4. Verify app is approved in AdMob

## Privacy and App Tracking Transparency

iOS requires user consent for tracking. The AdMob SDK handles most of this automatically:

1. **App Tracking Transparency (ATT)**:
   - Required for personalized ads
   - Can request permission using `ATTrackingManager.requestTrackingAuthorization()`
   - Users who decline still see non-personalized ads

2. **Privacy Policy**:
   - Must disclose ad usage in your privacy policy
   - Link to Google's privacy policy

3. **App Store Listing**:
   - Declare ad usage in App Privacy section
   - Mark that you collect device identifiers for advertising

## Resources

- [AdMob iOS Quick Start](https://developers.google.com/admob/ios/quick-start)
- [AdMob Banner Ads Guide](https://developers.google.com/admob/ios/banner)
- [AdMob Policy Center](https://support.google.com/admob/topic/2745287)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [Google Mobile Ads SDK Release Notes](https://developers.google.com/admob/ios/rel-notes)

## Support

For issues with:
- **AdMob account or setup**: Contact Google AdMob Support
- **Code integration**: Check console logs and this documentation
- **Policy violations**: Review AdMob Policy Center

