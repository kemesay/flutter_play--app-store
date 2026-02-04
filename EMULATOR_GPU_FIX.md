# Emulator GPU Driver Issue - Fix Guide

## Problem
- **GPU Driver Warning**: Emulator detects incompatible GPU driver
- **Emulator Not Responding**: Emulator freezes or crashes on launch
- **Solution**: Use software rendering instead of hardware acceleration

## Quick Fix: Launch with Software Rendering

### Option 1: Launch via Flutter with Software Rendering

```bash
# Kill any hung emulators first
pkill -f emulator
adb kill-server

# Launch emulator with software rendering (safer, more compatible)
flutter emulators --launch Pixel_8a --args="-gpu swiftshader_indirect"
```

### Option 2: Launch via Android Studio with Software Rendering

1. Open **Android Studio**
2. Go to **Tools** → **Device Manager**
3. Click the **▼ dropdown** next to your emulator (not the play button)
4. Select **Cold Boot Now** (or **Wipe Data** if needed)
5. Before launching, click **Edit** (pencil icon) next to the emulator
6. In **Advanced Settings**:
   - **Graphics**: Change from **Automatic** or **Hardware** to **Software - GLES 2.0**
7. Click **Finish**
8. Launch the emulator

### Option 3: Launch via Command Line with Software Rendering

Find your Android SDK emulator path and launch:

```bash
# Find emulator path (usually in Android SDK)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin

# Launch with software rendering
$ANDROID_HOME/emulator/emulator -avd Pixel_8a -gpu swiftshader_indirect &
```

## Permanent Fix: Update Emulator Configuration

### Method 1: Edit AVD Config File Directly

```bash
# Find your AVD config file
ls ~/.android/avd/

# Edit the config.ini file for your emulator (e.g., Pixel_8a.avd/config.ini)
nano ~/.android/avd/Pixel_8a.avd/config.ini
```

Find and change these lines:
```ini
# Change from:
hw.gpu.enabled = yes
hw.gpu.mode = host

# To:
hw.gpu.enabled = yes
hw.gpu.mode = swiftshader_indirect
```

Or for pure software rendering:
```ini
hw.gpu.enabled = no
```

Save and restart the emulator.

### Method 2: Use Android Studio AVD Manager

1. **Tools** → **Device Manager**
2. Click **Edit** (pencil icon) next to your emulator
3. Click **Show Advanced Settings**
4. Under **Graphics**:
   - Select **Software - GLES 2.0** (most compatible)
   - Or **Software - GLES 1.1** (if 2.0 doesn't work)
5. Click **Finish**
6. Restart the emulator

## Alternative: Update GPU Drivers

If you want to use hardware acceleration (faster but requires compatible drivers):

### For Linux (NVIDIA)
```bash
# Check current driver
nvidia-smi

# Update NVIDIA drivers
sudo apt update
sudo apt install nvidia-driver-535  # or latest version
sudo reboot
```

### For Linux (Intel/AMD)
```bash
# Check GPU info
lspci | grep VGA

# Update Mesa drivers
sudo apt update
sudo apt install mesa-utils
sudo apt install libgl1-mesa-glx libgl1-mesa-dri
```

### For Linux (Generic)
```bash
# Install/update graphics drivers
sudo apt update
sudo apt install xserver-xorg-video-all
```

## Verify Fix

After applying the fix:

```bash
# 1. Launch emulator with software rendering
flutter emulators --launch Pixel_8a --args="-gpu swiftshader_indirect"

# 2. Wait for boot (30-60 seconds)
sleep 30

# 3. Check if emulator is running
adb devices

# 4. Verify it's responsive
adb shell getprop sys.boot_completed
# Should return: 1
```

## Performance Notes

- **Software Rendering**: Slower but more stable and compatible
- **Hardware Acceleration**: Faster but requires compatible GPU drivers
- **Recommendation**: Use software rendering for development/testing, hardware for performance testing

## Troubleshooting Commands

```bash
# Kill all emulators
pkill -f emulator
adb kill-server

# Check emulator status
adb devices

# Check GPU acceleration support
emulator -accel-check

# Launch with verbose logging (for debugging)
emulator -avd Pixel_8a -gpu swiftshader_indirect -verbose
```

## If Emulator Still Crashes

1. **Increase RAM allocation**:
   - Edit AVD config: `hw.ramSize = 2048` (or higher)

2. **Reduce resolution**:
   - Edit AVD config: `hw.lcd.width = 720` and `hw.lcd.height = 1280`

3. **Use cold boot**:
   ```bash
   emulator -avd Pixel_8a -no-snapshot-load -gpu swiftshader_indirect
   ```

4. **Check system resources**:
   ```bash
   free -h  # Check available RAM
   htop     # Check CPU usage
   ```
