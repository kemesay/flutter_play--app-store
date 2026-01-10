# Build Fix - NDK llvm-strip Error

## Problem

Build was failing with error:
```
Execution failed for task ':app:stripReleaseDebugSymbols'.
> A problem occurred starting process 'command '/home/mesay/Android/Sdk/ndk/25.1.8937393/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip''
```

**Root Cause:**
- NDK installation at `/home/mesay/Android/Sdk/ndk/25.1.8937393` is incomplete (only 16KB)
- The `llvm-strip` tool is missing from the NDK toolchain
- Full NDK installation should be several hundred MB

## Solution Applied

### 1. Removed Explicit NDK Version
- Commented out `ndkVersion = "25.1.8937393"` in `build.gradle`
- Gradle will now use default or properly installed NDK

### 2. Disabled Debug Symbol Stripping
- Removed `ndk { debugSymbolLevel = 'FULL' }` configuration
- Added `packagingOptions { doNotStrip '**/*.so' }` to prevent stripping
- Added task configuration to disable `stripDebugSymbols` tasks

**Files Modified:**
- `android/app/build.gradle`

## Changes Made

```gradle
android {
    // Removed explicit NDK version
    // ndkVersion = "25.1.8937393"
    
    buildTypes {
        release {
            signingConfig = signingConfigs.release
            // Disabled debug symbol stripping
            // ndk {
            //     debugSymbolLevel = 'FULL'
            // }
        }
    }
    
    packagingOptions {
        // Prevent stripping of debug symbols
        doNotStrip '**/*.so'
    }
}

// Disable stripDebugSymbols task
afterEvaluate {
    tasks.matching { it.name.contains("stripDebugSymbols") }.configureEach {
        enabled = false
    }
}
```

## Impact

### Positive
- ✅ Build should now complete successfully
- ✅ App bundle will be created without errors
- ✅ Debug symbols will remain in the bundle (not stripped)

### Trade-offs
- ⚠️ Debug symbols won't be stripped (larger bundle size)
- ⚠️ You'll still see the debug symbols warning in Play Console
- ℹ️ This is acceptable - the warning is non-blocking

## Next Steps

### 1. Rebuild the App Bundle

```bash
cd /home/mesay/Desktop/Sisay_Project/transport-merge/Oda-black-car-Service
flutter clean
flutter build appbundle --release
```

### 2. Optional: Reinstall NDK (Recommended for Future)

To properly fix the NDK installation:

1. Open Android Studio
2. Go to **Tools** → **SDK Manager**
3. Select **SDK Tools** tab
4. Uncheck and recheck **NDK (Side by side)**
5. Click **Apply** to reinstall

Or via command line:
```bash
/home/mesay/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --uninstall "ndk;25.1.8937393"
/home/mesay/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "ndk;25.1.8937393"
```

**Note:** This requires a stable internet connection as NDK is ~1GB download.

## Alternative: Use Different NDK Version

If you want to specify a different NDK version:

1. Check available NDK versions:
   ```bash
   /home/mesay/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --list | grep "ndk"
   ```

2. Install a specific version:
   ```bash
   /home/mesay/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "ndk;21.4.7075529"
   ```

3. Update `build.gradle`:
   ```gradle
   ndkVersion = "21.4.7075529"
   ```

## Verification

After applying the fix, rebuild:
```bash
flutter clean
flutter build appbundle --release
```

You should see:
- ✅ No `llvm-strip` errors
- ✅ Build completes successfully
- ✅ `app-release.aab` created in `build/app/outputs/bundle/release/`

## Notes

- The build fix is a **workaround** - not a permanent solution
- For production, consider reinstalling the NDK properly
- The debug symbols warning in Play Console is still expected (can be ignored for Flutter apps)
- Bundle size may be slightly larger due to non-stripped symbols, but this is acceptable
