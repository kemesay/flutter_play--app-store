# 16KB Page Size Emulator Setup Guide

## Overview

Android 15+ supports devices with 16KB memory page sizes. To test your app on such devices, you need to create an emulator with a 16KB page size system image. This guide shows you how to set up and use a 16KB emulator.

## Prerequisites

- Android Studio installed
- Android SDK Platform 35 (Android 15) or higher
- Android SDK Build-Tools 35.0.0 or higher

## Step 1: Install 16KB Page Size System Image

1. **Open Android Studio**
2. Go to **Tools** → **SDK Manager** (or click the SDK Manager icon)
3. Click on the **SDK Platforms** tab
4. Check **Show Package Details** (bottom right)
5. Expand **Android 15.0 (API 35)** or **Android 16.0 (API 36)**
6. Look for system images with **"16KB Page Size"** in the name:
   - **Google APIs ARM 64 v8a System Image (16KB Page Size)**
   - **Google Play ARM 64 v8a System Image (16KB Page Size)**
7. Check the box next to the 16KB system image you want
8. Click **Apply** and wait for the download to complete

## Step 2: Create 16KB Emulator via Android Studio

### Method A: Using Device Manager (Recommended)

1. In Android Studio, go to **Tools** → **Device Manager**
2. Click **Create Device** (or the **+** button)
3. Select a device definition (e.g., **Pixel 8** or **Pixel 8 Pro**)
4. Click **Next**
5. In the **System Image** selection:
   - Look for system images with **"16KB Page Size"** in the name
   - Select: **Google APIs ARM 64 v8a System Image (16KB Page Size)** or **Google Play ARM 64 v8a System Image (16KB Page Size)**
   - Make sure the API level is **35** or higher
6. Click **Next**
7. Configure the AVD:
   - **AVD Name**: `Pixel_8_16KB` (or any name you prefer)
   - **Startup orientation**: Portrait
   - **Graphics**: Automatic (or Hardware - GLES 2.0 for better performance)
8. Click **Finish**

### Method B: Using Command Line (avdmanager)

```bash
# List available system images with 16KB support
sdkmanager --list | grep "16KB"

# Create AVD with 16KB system image
avdmanager create avd \
  -n Pixel_8_16KB \
  -k "system-images;android-35;google_apis;arm64-v8a" \
  -d "pixel_8" \
  --force

# Note: Replace "google_apis" with the exact package name from sdkmanager --list
# Look for packages containing "16KB" in the name
```

## Step 3: Launch the 16KB Emulator

### Using Android Studio
1. Go to **Tools** → **Device Manager**
2. Find your 16KB emulator (e.g., `Pixel_8_16KB`)
3. Click the **▶️ Play** button
4. Wait for the emulator to boot (may take 1-2 minutes)

### Using Command Line
```bash
# List all AVDs
emulator -list-avds

# Launch the 16KB emulator
emulator -avd Pixel_8_16KB
```

### Using Flutter
```bash
# List available emulators
flutter emulators

# Launch the 16KB emulator
flutter emulators --launch Pixel_8_16KB
```

## Step 4: Verify 16KB Page Size

Once the emulator is running, verify it's using 16KB pages:

```bash
# Connect to the emulator
adb shell

# Check page size (should show 16384 = 16KB)
getconf PAGE_SIZE

# Or check kernel page size
cat /proc/cpuinfo | grep -i "page size"

# Exit adb shell
exit
```

Expected output: `16384` (16KB) instead of `4096` (4KB)

## Step 5: Test Your App on 16KB Emulator

1. **Build your app** (if not already built):
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Install and run on the 16KB emulator**:
   ```bash
   # Make sure the 16KB emulator is running
   flutter devices
   
   # Install the APK
   flutter install
   
   # Or run directly
   flutter run --release
   ```

3. **Test critical functionality**:
   - App installation (should not fail with `INSTALL_FAILED_INVALID_APK`)
   - App launch (should not crash on startup)
   - Native library loading (maps, location services, etc.)
   - All major features

## Step 6: Verify 16KB Alignment of Your APK

After building, verify your APK is correctly aligned:

```bash
# Build release APK
flutter build apk --release

# Check alignment (Linux/Mac)
$ANDROID_HOME/build-tools/35.0.0/zipalign -v -c -P 16 4 build/app/outputs/flutter-apk/app-release.apk

# Or if ANDROID_HOME is not set, use full path:
# /home/mesay/Android/Sdk/build-tools/35.0.0/zipalign -v -c -P 16 4 build/app/outputs/flutter-apk/app-release.apk
```

**Expected output**: `Verification successful` means your APK is 16KB-aligned.

## Troubleshooting

### Emulator Won't Start

1. **Check system requirements**:
   - Ensure you have enough RAM (at least 8GB recommended)
   - Enable virtualization in BIOS (for Intel/AMD processors)

2. **Check KVM (Linux)**:
   ```bash
   # Check if KVM is available
   emulator -accel-check
   
   # If not available, install KVM:
   sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
   sudo adduser $USER kvm
   ```

3. **Try cold boot**:
   ```bash
   emulator -avd Pixel_8_16KB -no-snapshot-load
   ```

### App Fails to Install

If you see `INSTALL_FAILED_INVALID_APK: Failed to extract native libraries`:
- Your native libraries are not 16KB-aligned
- **Solution**: Upgrade to NDK r27 or r28 and rebuild (see main build.gradle configuration)

### App Crashes on Launch

1. **Check logcat**:
   ```bash
   adb logcat | grep -i "crash\|fatal\|error"
   ```

2. **Check if native libraries load**:
   ```bash
   adb logcat | grep -i "dlopen\|library"
   ```

3. **Verify NDK version** in `android/app/build.gradle`:
   - Should be NDK r27 (`27.0.12077973`) or r28 (`28.0.12433566`)
   - Not NDK r26 or older

## Quick Reference Commands

```bash
# List all emulators
flutter emulators
emulator -list-avds

# Launch 16KB emulator
flutter emulators --launch Pixel_8_16KB
# or
emulator -avd Pixel_8_16KB

# Check connected devices
flutter devices
adb devices

# Check page size on running emulator
adb shell getconf PAGE_SIZE

# Build and test
flutter clean
flutter pub get
flutter build apk --release
flutter install

# Verify APK alignment
$ANDROID_HOME/build-tools/35.0.0/zipalign -v -c -P 16 4 build/app/outputs/flutter-apk/app-release.apk
```

## Important Notes

1. **16KB emulators are slower** than 4KB emulators due to the larger page size
2. **First boot takes longer** - be patient (2-3 minutes)
3. **Test thoroughly** - 16KB page size can reveal issues not visible on 4KB devices
4. **Google Play requirement**: Starting November 1, 2025, all apps targeting Android 15+ must support 16KB page sizes

## Next Steps

After successfully testing on a 16KB emulator:
1. Fix any issues found during testing
2. Rebuild with NDK r27/r28 if not already done
3. Verify APK alignment with zipalign
4. Upload to Google Play Console
5. The Play Console should no longer show 16KB warnings
