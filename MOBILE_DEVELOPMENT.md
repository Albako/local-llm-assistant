# Mobile Development Guide for Open WebUI

This guide explains how to use Capacitor and the mobile utilities in the Open WebUI application.

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Build for Web
```bash
npm run build
```

### 3. Initialize Android Project (First Time Only)
```bash
npm run cap:init
```

### 4. Build and Deploy to Android
```bash
npm run build:android
```

Then open Android Studio and run the app:
```bash
npm run cap:open
```

## Using Mobile Utilities in Your Svelte Components

The `$lib/mobile` module provides utility functions for detecting and using mobile features:

### Detecting if Running on Native Mobile

```svelte
<script>
  import { isNativeMobile } from '$lib/mobile';
  
  let isMobile = isNativeMobile();
</script>

{#if isMobile}
  <p>Running on native Android/iOS</p>
{:else}
  <p>Running in web browser</p>
{/if}
```

### Checking Network Status

```svelte
<script>
  import { checkNetworkStatus, listenToNetworkChanges } from '$lib/mobile';
  import { onMount } from 'svelte';
  
  let isOnline = navigator.onLine;
  
  onMount(async () => {
    const status = await checkNetworkStatus();
    isOnline = status.connected;
    
    // Listen for changes
    const unsubscribe = listenToNetworkChanges((connected) => {
      isOnline = connected;
    });
    
    return unsubscribe;
  });
</script>

<div>
  {#if !isOnline}
    <div class="offline-notice">
      You are currently offline
    </div>
  {/if}
</div>
```

### Handling App Lifecycle (Pause/Resume)

```svelte
<script>
  import { setupAppLifecycle } from '$lib/mobile';
  import { onMount } from 'svelte';
  
  onMount(() => {
    const unsubscribe = setupAppLifecycle(
      () => {
        console.log('App paused');
        // Save state, pause videos, etc.
      },
      () => {
        console.log('App resumed');
        // Restore state, resume videos, etc.
      }
    );
    
    return unsubscribe;
  });
</script>
```

### Handling Android Back Button

```svelte
<script>
  import { setupBackButton } from '$lib/mobile';
  import { onMount } from 'svelte';
  
  onMount(() => {
    const unsubscribe = setupBackButton(() => {
      // Handle back button press
      console.log('Back button pressed');
      // e.g., close modal, go to previous page, etc.
    });
    
    return unsubscribe;
  });
</script>
```

### Getting Device Information

```svelte
<script>
  import { getDeviceInfo, getPlatformInfo } from '$lib/mobile';
  
  let deviceInfo: any = null;
  let platformInfo: any = null;
  
  onMount(async () => {
    deviceInfo = await getDeviceInfo();
    platformInfo = await getPlatformInfo();
  });
</script>

<div>
  {#if deviceInfo}
    <p>Device Model: {deviceInfo.model}</p>
    <p>OS: {deviceInfo.platform} {deviceInfo.osVersion}</p>
  {/if}
  
  {#if platformInfo}
    <p>Manufacturer: {platformInfo.manufacturer}</p>
  {/if}
</div>
```

## Using the Mobile Wrapper Component

The `MobileWrapper.svelte` component provides:
- Safe area handling for notched devices
- Offline status indicator
- Mobile-specific styling

Usage in your layout:

```svelte
<script>
  import MobileWrapper from '$lib/mobile/MobileWrapper.svelte';
</script>

<MobileWrapper>
  <!-- Your content here -->
</MobileWrapper>
```

The component automatically handles:
- Status bar padding and notches
- Network status display
- Mobile-optimized spacing

## API Configuration for Mobile

When building for Android, ensure your backend API is accessible:

1. **Development**: The app can connect to `localhost` with appropriate proxy configuration
2. **Production**: Update the API endpoint in your environment

Example:

```typescript
// src/lib/config.ts
export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
```

Configure in `.env`:
```
VITE_API_URL=https://api.example.com
```

## Safe Area Handling

Capacitor automatically handles safe areas (notches, rounded corners) using CSS environment variables:

```css
/* These are available in CSS */
env(safe-area-inset-top)
env(safe-area-inset-right)
env(safe-area-inset-bottom)
env(safe-area-inset-left)
```

The MobileWrapper component uses these automatically.

## Available Capacitor Plugins

The following plugins are available in this project:

- **@capacitor/app**: App-level functionality
- **@capacitor/device**: Device information
- **@capacitor/network**: Network status
- **@capacitor/keyboard**: Keyboard control
- **@capacitor/android**: Android-specific features

### Installing Additional Plugins

```bash
npm install --save-dev @capacitor/camera
npx cap sync
```

Then use in your code:

```typescript
import { Camera, CameraResultType } from '@capacitor/camera';

async function takePhoto() {
  const image = await Camera.getPhoto({
    quality: 90,
    allowEditing: true,
    resultType: CameraResultType.Uri
  });
}
```

## Testing on Device

### USB Debugging

1. Connect Android device via USB
2. Enable USB Debugging in device settings
3. Trust the computer when prompted
4. Check connection: `adb devices`

### Via Android Studio

1. Open the android folder: `npm run cap:open`
2. Select your device
3. Click Run (Green play button)
4. View logs in Logcat

### Via Command Line

```bash
cd android
./gradlew installDebug
```

## Debugging

### View Console Logs

In Android Studio:
1. View > Tool Windows > Logcat
2. Filter by "Capacitor" or your app ID

### Chrome DevTools

1. Open Chrome: `chrome://inspect/#devices`
2. Select your app
3. Click "Inspect"

## Building for Release

See [ANDROID_BUILD.md](./ANDROID_BUILD.md) for detailed instructions on:
- Building signed APKs
- Creating app bundles for Google Play
- Publishing to Google Play Store

## Troubleshooting

### App won't load
- Check Logcat for errors
- Ensure backend is accessible
- Verify API URL configuration

### Capacitor plugins not working
- Run `npx cap sync` to ensure plugins are installed
- Rebuild: `npm run build:android`
- Check plugin documentation for required permissions

### Network issues
- Check CORS configuration on backend
- Verify network connectivity
- Use `listenToNetworkChanges` to detect offline state

### Build errors
- Clean: `cd android && ./gradlew clean`
- Rebuild: `npm run build:android`
- Check Android SDK version matches gradle configuration

## Resources

- [Capacitor Documentation](https://capacitorjs.com/)
- [Capacitor Plugins](https://capacitorjs.com/docs/plugins)
- [Android Development Guide](https://developer.android.com/docs)
- [Android Studio Setup](https://developer.android.com/studio)
- [PWA Documentation](https://web.dev/progressive-web-apps/)
