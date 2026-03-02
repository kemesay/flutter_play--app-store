# iOS Deployment Fix - iPhone 14 Pro Max Crash/Timeout

## Problem Summary
- Build succeeds but deployment fails
- "Timed out waiting for destination to become available"
- "Device may need to be unlocked to recover from preparation errors"
- Wireless debugging timeout on iOS 26.2.1

## Root Causes
1. **Wireless debugging is unreliable** - Slower and more prone to timeouts
2. **Device preparation errors** - Cached errors from previous failed deployments
3. **Xcode derived data** - Corrupted build cache
4. **Device locked or in bad state** - Needs reset

## ✅ Solution Steps (Do ALL of these)

### Step 1: Fix Device State (CRITICAL)

**On your iPhone 14 Pro Max:**

1. **Unlock the device** - Make sure it's not locked
2. **Trust the computer** (if using USB):
   - Connect via USB
   - When prompted "Trust This Computer?", tap **Trust**
   - Enter your passcode
3. **Enable Developer Mode**:
   - Settings → Privacy & Security → Developer Mode → **Enable**
   - Restart the device when prompted
4. **Check device is ready**:
   - Settings → General → VPN & Device Management
   - Your developer certificate should be listed

### Step 2: Use USB Connection (NOT Wireless)

**Wireless debugging is causing the timeout. Use USB instead:**

1. **Connect iPhone via USB cable** to your Mac
2. **Disable wireless debugging**:
   - On iPhone: Settings → Developer → Network → **Disable wireless debugging**
3. **Verify USB connection**:
   ```bash
   xcrun devicectl list devices
   # Should show your iPhone connected via USB
   ```

### Step 3: Clean Xcode Build Cache

```bash
cd ~/Desktop/Sisay_Project/transport-merge/oda-black-car-service

# Clean Flutter build
flutter clean

# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf build/

# Reinstall pods
pod install --repo-update

cd ..
```

### Step 4: Reset Device Preparation in Xcode

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **In Xcode**:
   - Go to **Window** → **Devices and Simulators**
   - Select your iPhone 14 Pro Max
   - Click **"Use for Development"** (if shown)
   - If device shows errors, click **"Unpair Device"** then reconnect

3. **Clean build folder**:
   - In Xcode: **Product** → **Clean Build Folder** (Shift+Cmd+K)

### Step 5: Update Deployment Target (if needed)

Your current deployment target is iOS 12.0, which should work. But for iPhone 14 Pro Max with iOS 26.2.1 (beta), you might need iOS 13.0+.

**Check and update if needed:**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project in left sidebar
3. Select **Runner** target
4. Go to **General** tab
5. Set **Minimum Deployments** to **iOS 13.0** (or higher)
6. Go to **Build Settings** tab
7. Search for `IPHONEOS_DEPLOYMENT_TARGET`
8. Set to **13.0** (or match your device's minimum)

### Step 6: Rebuild and Deploy

```bash
cd ~/Desktop/Sisay_Project/transport-merge/oda-black-car-service

# Make sure device is connected via USB
flutter devices
# Should show your iPhone (not "wireless")

# Clean and rebuild
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Deploy with USB connection
flutter run -d <your-iphone-device-id>
# Or let Flutter auto-detect: flutter run
```

### Step 7: If Still Failing - Manual Xcode Deploy

If Flutter still fails, deploy directly from Xcode:

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select device**:
   - Top toolbar: Select your iPhone 14 Pro Max (not simulator)

3. **Select scheme**:
   - Product → Scheme → **Runner**

4. **Build and Run**:
   - Press **Cmd+R** or click **Play** button
   - Xcode will handle deployment more reliably

## Alternative: Increase Timeout (Temporary Workaround)

If you MUST use wireless debugging:

```bash
# Set longer timeout
export FLUTTER_XCODE_TIMEOUT=300

# Run with longer timeout
flutter run -d <device-id> --device-timeout 300
```

But **USB is strongly recommended** for reliability.

## Troubleshooting Specific Errors

### Error: "Device may need to be unlocked"
- **Fix**: Unlock iPhone, trust computer, enable Developer Mode

### Error: "Timed out waiting for destination"
- **Fix**: Use USB instead of wireless, clean derived data

### Error: "Could not build precompiled application"
- **Fix**: Clean build cache, reinstall pods, check deployment target

### Error: Code signing issues
- **Fix**: 
  1. Xcode → Preferences → Accounts → Add your Apple ID
  2. Select team in Runner target → Signing & Capabilities
  3. Enable "Automatically manage signing"

## Verification

After successful deployment:

```bash
# Check app is installed
xcrun devicectl device info app --device <device-id> --bundle-id com.odatransportation.app

# Check device connection
flutter devices
# Should show: iPhone (USB connected)
```

## Prevention

1. **Always use USB** for development (faster, more reliable)
2. **Keep device unlocked** during deployment
3. **Clean build cache** regularly: `flutter clean && cd ios && pod install`
4. **Update Xcode** to latest version
5. **Keep iOS device** updated (but not beta if possible)

---

**Note**: iOS 26.2.1 seems unusual (iOS 26 doesn't exist in public releases). If this is a beta, consider using a stable iOS version for testing, or ensure your Xcode version supports that iOS version.
