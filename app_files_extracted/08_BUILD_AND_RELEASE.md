# 🚀 Build, Release & Play Store Guide

## Running the App Locally

### Prerequisites
```bash
# Check Flutter setup
flutter doctor

# All items should show ✓
# If Android toolchain shows ✗, install Android Studio
```

### Install Dependencies
```bash
cd your_project_folder
flutter pub get
```

### Run on Device/Emulator
```bash
# List connected devices
flutter devices

# Run debug build
flutter run

# Run on specific device
flutter run -d emulator-5554
```

### Hot Reload vs Hot Restart
- `r` in terminal → Hot reload (keep state)
- `R` in terminal → Hot restart (reset state)
- Use hot restart after changing Firebase/Riverpod providers

---

## Building Release APK

### Step 1: Create Keystore (ONE TIME ONLY)
```bash
keytool -genkey -v -keystore ~/kochigo-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kochigo
```
Fill in the prompts. **SAVE THIS FILE AND PASSWORD FOREVER.**

### Step 2: Reference Keystore in Flutter
Create `android/key.properties` (DO NOT commit to git):
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=kochigo
storeFile=/Users/yourname/kochigo-release.jks
```

Add to `.gitignore`:
```
android/key.properties
*.jks
```

### Step 3: Update android/app/build.gradle
```gradle
// Load key.properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Step 4: Update App Version
In `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

### Step 5: Build APK
```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (required for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## App Icon Setup
```bash
# Add flutter_launcher_icons package
flutter pub add flutter_launcher_icons --dev

# Place your icon (1024×1024 PNG) at assets/icon/icon.png

# Add to pubspec.yaml:
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"

# Generate icons
dart run flutter_launcher_icons
```

---

## Play Store Submission Checklist

### Assets to Prepare
- [ ] App icon: 512×512 PNG (no alpha)
- [ ] Feature graphic: 1024×500 PNG
- [ ] Screenshots: Minimum 2, recommended 4-8
  - Phone screenshots: 1080×1920px (portrait)
- [ ] App bundle (.aab) signed release build

### App Listing (Copy-Paste Ready)

**App Name:** KochiGo — Events in Kochi

**Short Description (80 chars max):**
Discover what's happening in Kochi today and this weekend.

**Full Description:**
```
KochiGo is your personal events guide for Kochi, Kerala.

Find the best events happening today and this weekend — comedy shows, live music, tech meetups, fitness sessions, art walks, and workshops.

✨ NO SIGN-UP REQUIRED — just open and explore
🗓️ TODAY & WEEKEND view — always relevant
🎭 Browse by category — find exactly what you love
🔖 SAVE events — bookmark and never miss out
📍 One-tap directions — straight to Google Maps

Kochi has incredible events happening every weekend. KochiGo makes sure you never miss them.

Built for Kochiites, by Kochiites.
```

**Category:** Events

**Content Rating:** Everyone

**Privacy Policy:** Required — host a simple one on GitHub Pages

---

## Simple Privacy Policy Template

Host this at: `https://yourusername.github.io/kochigo-privacy`

```markdown
# KochiGo Privacy Policy

Last updated: April 2025

KochiGo does not collect any personal information.

The app stores your saved/bookmarked events locally on your device only. 
This data is never transmitted to any server.

Event data is fetched from our Firebase Firestore database (read-only).

We do not use analytics, advertising SDKs, or tracking.

Contact: youremail@gmail.com
```

---

## Future Monetization Plan (v2+)

1. **Promoted Listings** — Event organizers pay ₹500-2000 to feature their event at the top
2. **Event Organizer Dashboard** — Monthly subscription (₹999/month) to self-publish events
3. **Sponsored Category** — "Powered by Brand X" on a category filter
4. **City Expansion** — Launch in Trivandrum, Thrissur — same model

> Keep the app itself free forever. Revenue from B2B (organizers), not users.
