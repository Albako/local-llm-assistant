#!/bin/bash

# Exit on any error
set -e

echo "Starting Android build process..."

# 1. Install dependencies
echo "Installing dependencies..."
npm install

# 2. Build the web frontend (assuming npm run build exists)
echo "Building web frontend..."
npm run build

# 3. Sync Capacitor project
echo "Syncing Capacitor..."
npx cap sync android

# 4. Navigate to android folder and build APK
echo "Building APK using Gradle..."
cd android
./gradlew assembleDebug

echo "Build finished successfully!"
echo "The APK file can be found in: android/app/build/outputs/apk/debug/app-debug.apk"
