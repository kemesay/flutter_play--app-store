# 16KB Emulator Performance Fix - Lag & Crash Solutions

## Problem
- Emulator freezes or becomes unresponsive
- Very laggy performance
- "Emulator Is Not Responding" dialog appears

## ✅ Optimizations Applied

I've optimized your `Pixel_8_16KB` emulator configuration with the following changes:

### 1. **Reduced CPU Cores**: 4 → 2 cores
   - Less CPU overhead
   - More stable on systems with limited resources

### 2. **Reduced Resolution**: 2400x1080 → 1920x1080
   - Lower GPU/CPU load
   - Faster rendering

### 3. **Reduced RAM**: 2048MB → 1536MB
   - Less memory pressure
   - More stable operation

### 4. **Reduced Heap Size**: 228MB → 192MB
   - Lower memory footprint

### 5. **Disabled Fast Boot**: `forceFastBoot=no`
   - More stable boot process
   - Prevents corruption issues

### 6. **Disabled Unnecessary Sensors**:
   - Pressure sensor: disabled
   - Proximity sensor: disabled
   - Audio input: disabled (not needed for testing)

### 7. **Software Rendering**: Already set to `swiftshader_indirect`
   - Avoids GPU driver issues
   - More compatible

## 🚀 How to Launch (Optimized)

### Method 1: Using the Launch Script (Recommended)

```bash
# Run the optimized launch script
./launch_16kb_emulator.sh
```

This script:
- Cleans up any hung processes
- Launches with optimized settings
- Waits for boot completion
- Verifies 16KB page size
- Shows status

### Method 2: Using Flutter Command

```bash
# Kill any existing emulators first
pkill -f emulator
adb kill-server

# Launch via Flutter (will use optimized config)
flutter emulators --launch Pixel_8_16KB
```

### Method 3: Direct Emulator Command (Most Control)

```bash
# Set paths
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator

# Launch with optimizations
$ANDROID_HOME/emulator/emulator \
  -avd Pixel_8_16KB \
  -gpu swiftshader_indirect \
  -no-audio \
  -memory 1536 \
  -cores 2 \
  -netspeed full \
  -netdelay none &
```

## ⏱️ Expected Boot Time

- **First launch**: 60-90 seconds (cold boot)
- **Subsequent launches**: 30-45 seconds (uses snapshots)

**Be patient!** The emulator needs time to fully initialize.

## 🔍 Verify It's Working

After emulator boots:

```bash
# Check if device is connected
adb devices
# Should show: emulator-5554    device

# Verify 16KB page size
adb shell getconf PAGE_SIZE
# Should show: 16384

# Check boot status
adb shell getprop sys.boot_completed
# Should show: 1
```

## 🐛 If Still Laggy or Crashing

### Option 1: Further Reduce Resources

Edit `~/.android/avd/Pixel_8_16KB.avd/config.ini`:

```ini
# Reduce RAM further
hw.ramSize=1024

# Reduce resolution more
hw.lcd.height=1280
hw.lcd.width=720
hw.lcd.density=280

# Reduce heap
vm.heapSize=128
```

### Option 2: Use Cold Boot (Fresh Start)

```bash
# Kill emulator
pkill -f emulator

# Launch with cold boot (no snapshots)
$ANDROID_HOME/emulator/emulator \
  -avd Pixel_8_16KB \
  -gpu swiftshader_indirect \
  -no-snapshot-load \
  -no-snapshot-save \
  -memory 1536 \
  -cores 2 &
```

### Option 3: Close Other Applications

- Close Android Studio (if not needed)
- Close other heavy applications
- Free up RAM: `free -h` (should have at least 4GB free)

### Option 4: Check System Resources

```bash
# Check available RAM
free -h

# Check CPU usage
htop

# Check if KVM is available (for hardware acceleration)
emulator -accel-check
```

## 📝 Performance Tips

1. **Don't run multiple emulators** at the same time
2. **Wait for full boot** before interacting (wait for home screen)
3. **Use snapshots** for faster subsequent launches (default)
4. **Close Android Studio** if not needed (saves ~1-2GB RAM)
5. **First launch is always slower** - be patient

## 🎯 Quick Test After Launch

Once emulator is running:

```bash
# Run your Flutter app
flutter run -d emulator-5554

# Or if Flutter detects it automatically
flutter run
```

## 📊 Current Configuration Summary

- **CPU Cores**: 2
- **RAM**: 1536MB
- **Resolution**: 1920x1080
- **GPU**: Software rendering (SwiftShader)
- **Heap**: 192MB
- **Fast Boot**: Disabled (more stable)
- **Audio**: Disabled (saves resources)
- **Sensors**: Minimal (only essential ones)

## ✅ Success Indicators

You'll know it's working when:
- ✅ Emulator window opens without freezing
- ✅ Android home screen appears (may take 60-90 seconds)
- ✅ No "Not Responding" dialogs
- ✅ Smooth interaction (may be slightly slower than hardware acceleration, but stable)
- ✅ `adb devices` shows the emulator
- ✅ `getconf PAGE_SIZE` returns `16384`

## 🆘 Still Having Issues?

If the emulator still crashes or freezes:

1. **Check logs**: `tail -f /tmp/emulator.log`
2. **Try a different emulator**: Use `Medium_Phone_API_36.1` (lighter weight)
3. **Check system resources**: Ensure you have enough RAM/CPU free
4. **Update Android SDK**: `sdkmanager --update`
5. **Recreate the emulator**: Delete and recreate in Android Studio

---

**Note**: 16KB emulators are inherently more resource-intensive than 4KB emulators. The optimizations above balance performance with stability. Some lag is normal, but it should be usable for testing.
