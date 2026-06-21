# Android Build Guide for Open WebUI

This guide explains how to build and deploy the Open WebUI application as an Android app using Capacitor.

## Prerequisites

Before you can build the Android app, ensure you have the following installed:

### 1. **Java Development Kit (JDK)**
   - Required: JDK 11 or higher
   - Install from: [Oracle JDK](https://www.oracle.com/java/technologies/downloads/) or use OpenJDK
   - Verify installation:
     ```bash
     java -version
     javac -version
     ```

### 2. **Android SDK**
   - Download [Android Studio](https://developer.android.com/studio) (includes Android SDK)
   - Or download [Command-line tools only](https://developer.android.com/studio#command-tools)
   - Set `ANDROID_HOME` environment variable:
     ```bash
     # macOS/Linux
     export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
     export ANDROID_HOME=$HOME/Android/Sdk          # Linux
     
     # Windows
     set ANDROID_HOME=C:\Users\<YourUsername>\AppData\Local\Android\sdk
     ```
   - Add Android SDK tools to PATH:
     ```bash
     export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools
     ```

### 3. **Node.js and npm**
   - Required: Node.js 18.13.0 or higher
   - Verify: `node --version` and `npm --version`

### 4. **Gradle** (optional, comes with Android Studio)
   - Required: Gradle 7.0 or higher
   - Usually installed with Android Studio

## Setup Instructions

### 1. Install Dependencies
```bash
npm install
```

### 2. Build Web Assets
```bash
npm run build
```

This builds the SvelteKit application and generates static files in the `build/` directory.

### 3. Initialize Android Project (First Time Only)
```bash
npm run cap:init
```

This creates the `android/` directory with the Android project structure.

### 4. Sync Capacitor Files
```bash
npm run cap:sync
```

Or use the shorthand:
```bash
npx cap sync
```

This copies the web assets from the `build/` directory to the Android project.

## Building the Android App

### Option 1: Using Android Studio (Recommended for Development)

1. **Open the Android project:**
   ```bash
   npm run cap:open
   ```
   Or manually:
   ```bash
   open android  # macOS
   start android # Windows
   ```

2. **In Android Studio:**
   - Wait for Gradle to sync
   - Select a device or emulator
   - Click the **Run** button (green play icon) or press `Shift + F10`

### Option 2: Using Gradle (Command Line)

1. **Build a debug APK:**
   ```bash
   cd android
   ./gradlew assembleDebug
   ```

2. **Build a release APK:**
   ```bash
   cd android
   ./gradlew assembleRelease
   ```

3. **Install on connected device:**
   ```bash
   adb install app/build/outputs/apk/debug/app-debug.apk
   ```

### Option 3: Using npm Scripts

Build and prepare Android files:
```bash
npm run build:android
```

This runs:
1. `npm run build` - builds web assets
2. `npx cap sync` - syncs with Android
3. `npx cap copy android` - copies files to Android project

## Running the App

### On Android Device
1. Connect your Android device via USB
2. Enable USB Debugging on your device (Settings > Developer Options > USB Debugging)
3. Run: `adb devices` to verify connection
4. In Android Studio, select your device and click **Run**

### On Android Emulator
1. Create or select an emulator in Android Studio
2. Start the emulator
3. In Android Studio, select the emulator and click **Run**

## Configuration

### App Information
The app is configured in `capacitor.config.ts`:

```typescript
{
  appId: 'com.openwebui.app',        // Package name for Google Play
  appName: 'Open WebUI',              // Display name
  webDir: 'build',                    // Web assets directory
  server: {
    androidScheme: 'https'            // Scheme for URLs
  }
}
```

### Backend Connection

The app will connect to the backend based on the environment:

1. **Development**: Update the backend URL in your app's configuration
2. **Production**: Configure the API endpoint accordingly

If the backend is on a different host, ensure:
- CORS is properly configured
- Network security policies allow the connection

## Troubleshooting

### "Could not find android.jar"
- Ensure `ANDROID_HOME` is set correctly
- Run: `sdkmanager "platforms;android-34"` to install SDK

### "Gradle build failed"
- Clean gradle cache: `./gradlew clean`
- Rebuild: `./gradlew build`

### "Device not found"
- Check USB connection: `adb devices`
- Enable USB Debugging on device
- Accept USB debugging prompt on device

### App crashes on startup
- Check Logcat in Android Studio: View > Tool Windows > Logcat
- Look for error messages starting with "E/"

### White screen on app load
- Ensure `npm run build` was executed before syncing
- Verify backend URL is correct
- Check network connectivity

## Publishing to Google Play

1. **Generate a signed APK/AAB:**
   - In Android Studio: Build > Generate Signed Bundle / APK
   - Create or select a keystore file
   - Choose release build type

2. **Create a Google Play Developer account**

3. **Upload to Google Play Console**

4. **Set up app listing, screenshots, and description**

5. **Submit for review**

## Advanced Configuration

### Plugins

Additional Capacitor plugins are available:

- **@capacitor/app**: App-level features
- **@capacitor/device**: Device information
- **@capacitor/network**: Network status
- **@capacitor/keyboard**: Keyboard control
- **@capacitor/storage**: Local storage
- **@capacitor/camera**: Camera access
- **@capacitor/geolocation**: GPS location

Install with: `npm install @capacitor/[plugin-name]`

### Custom Permissions

Edit `android/app/src/main/AndroidManifest.xml` to add permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

For runtime permissions, use the Capacitor plugin APIs.

## Resources

- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Android Developer Guide](https://developer.android.com/docs)
- [Android Studio Setup](https://developer.android.com/studio/install)
- [Gradle Documentation](https://gradle.org/releases/)
