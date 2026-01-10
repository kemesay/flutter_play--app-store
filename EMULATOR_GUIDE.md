# How to Use Emulator for ODA Transportation Flutter App

## Quick Start

### 1. Launch an Android Emulator

You have 7 available emulators. To launch one, use:

```bash
# Launch a phone emulator (recommended)
flutter emulators --launch Pixel_8a

# Or launch a medium phone
flutter emulators --launch Medium_Phone_API_36.1

# Or launch a tablet
flutter emulators --launch Medium_Tablet

# Or launch 7-inch tablet
flutter emulators --launch Tablet_7inch

# Or launch 10-inch tablet
flutter emulators --launch Tablet_10inch
```

### 2. Wait for Emulator to Start

After running the launch command, wait for the Android emulator window to open and fully boot (this may take 30-60 seconds).

### 3. Verify Emulator is Running

Check if the emulator is detected:

```bash
flutter devices
```

You should see your emulator listed (e.g., "sdk gphone64 arm64" or similar).

### 4. Run the Flutter App

Once the emulator is running, execute:

```bash
flutter run
```

Or specify the device explicitly:

```bash
flutter run -d <device-id>
```

## Available Emulators

### Phones
- **Pixel_8a** - Google Pixel 8a phone (recommended for testing)
- **Medium_Phone_API_36.1** - Generic medium-sized phone

### Tablets
- **Tablet_7inch** - 7-inch WSVGA tablet (optimized for 7" screens)
- **Tablet_10inch** - 10.1-inch WXGA tablet (optimized for 10" screens)
- **Medium_Tablet** - Generic medium tablet

### Other Devices
- **Wear_OS_Small_Round** - Wear OS watch
- **XR_Headset** - VR/AR headset

## Alternative: Launch Emulator from Android Studio

1. Open Android Studio
2. Go to **Tools** → **Device Manager**
3. Click the ▶️ play button next to your desired emulator
4. Wait for it to boot
5. Run `flutter run` in your terminal

## Alternative: Use Command Line (avdmanager)

```bash
# List all available AVDs
emulator -list-avds

# Launch a specific AVD
emulator -avd Pixel_8a
```

## Troubleshooting

### Emulator Not Showing Up

1. Make sure Android SDK is properly installed:
   ```bash
   flutter doctor -v
   ```

2. Check if emulator is actually running:
   ```bash
   adb devices
   ```

3. Restart ADB if needed:
   ```bash
   adb kill-server
   adb start-server
   ```

### Emulator Too Slow

- Close other applications
- Increase emulator RAM in AVD settings
- Use a system image with fewer resources
- Enable hardware acceleration (if available)

### Create a New Emulator

If you need a different emulator:

```bash
flutter emulators --create --name MyCustomEmulator
```

Or use Android Studio's AVD Manager for more options.

## Running on Different Platforms

### Android Emulator (Current Setup)
```bash
flutter emulators --launch Pixel_8a
flutter run
```

### Linux Desktop
```bash
flutter run -d linux
```

### Chrome (Web)
```bash
flutter run -d chrome
```

## Hot Reload

Once the app is running:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Useful Commands

```bash
# List all devices (including emulators)
flutter devices

# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator-id>

# Run app on specific device
flutter run -d <device-id>

# Check Flutter setup
flutter doctor

# Get detailed Flutter info
flutter doctor -v
```
