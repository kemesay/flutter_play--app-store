# Google Play Store Upload Guide

## Version Information

- **Version Code**: 5 (incremented from 4)
- **Version Name**: 0.1.4 (incremented from 0.1.3)

## Steps to Upload to Play Store

### 1. Rebuild the App Bundle

Since we've updated the version code, rebuild the release bundle:

```bash
cd /home/mesay/Desktop/Sisay_Project/transport-merge/Oda-black-car-Service
flutter build appbundle --release
```

This will create: `build/app/outputs/bundle/release/app-release.aab`

### 2. Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to: **Release** → **Testing** → **Closed testing**
4. Click **Create new release** (or edit existing release)
5. Upload the new `.aab` file: `build/app/outputs/bundle/release/app-release.aab`

### 3. Handle Native Debug Symbols Warning

When you upload, you'll see a warning about missing debug symbols. Here are your options:

#### Option A: Ignore the Warning (Simplest)
- The warning is **not a blocker** - you can still publish your app
- Your app will work fine, but crash reports won't be as detailed
- Click **Review release** and proceed

#### Option B: Upload Debug Symbols (Recommended for Production)

If you want to upload debug symbols for better crash analysis:

1. After building, the debug symbols are included in the bundle when `debugSymbolLevel = 'FULL'` is set
2. However, Google Play Console may still show the warning for Flutter apps
3. For Flutter apps, symbols are typically embedded in the bundle itself
4. The warning is often a false positive for Flutter apps

#### Option C: Generate and Upload symbols.zip

If Google Play still requires a separate symbols file:

```bash
# The symbols should be automatically included in the bundle
# But if needed, you can verify with:
unzip -l build/app/outputs/bundle/release/app-release.aab | grep -i symbol
```

### 4. Fill in Release Notes

- **What's new in this version**: Add release notes describing changes
- **Version**: 0.1.4

### 5. Review and Rollout

1. Click **Review release**
2. Check all warnings and errors
3. If the debug symbols warning persists, you can still proceed (it's a warning, not an error)
4. Click **Start rollout to Closed testing**

## About the Debug Symbols Warning

**Why it appears:**
- Flutter apps contain native code (the Flutter engine)
- Google Play wants symbol files to help debug crashes

**Is it critical?**
- **No** - It's a warning, not an error
- Your app will work fine without uploading separate symbols
- Crash reports will still work, just with less detail

**For Flutter apps:**
- Flutter bundles symbols differently than native Android apps
- The symbols are often embedded in the bundle itself
- Google Play may not always detect them correctly
- This is a known issue with Flutter apps on Play Console

## Version Code Best Practices

- **Version code** must always increase with each release
- Each upload to Play Store must have a unique, higher version code
- If you upload version code 4, the next must be 5 or higher
- Version code cannot be reused or decreased

## Next Release

When creating the next release:
1. Increment `versionCode` in `android/app/build.gradle` (currently 5, next should be 6)
2. Optionally increment `version` in `pubspec.yaml` (currently 0.1.4, next could be 0.1.5 or 0.2.0)

## Troubleshooting

### "Version code already used" Error
- Make sure version code in `build.gradle` is higher than previous releases
- Check Play Console to see what version codes have been used
- Current version code: **5**

### Debug Symbols Warning Won't Go Away
- This is normal for Flutter apps
- The warning can be safely ignored
- Your app functionality is not affected

### Bundle Not Uploading
- Ensure the bundle file exists: `build/app/outputs/bundle/release/app-release.aab`
- Check file size (should be ~25-30 MB)
- Verify signing is configured correctly in `key.properties`
