# Emulator Optimization Guide

## Optimizations Applied

Both tablet emulators (7-inch and 10-inch) have been optimized for better stability and performance:

### Changes Made:

1. **RAM Increased**: 512MB → 2048MB
   - Prevents "System UI isn't responding" errors
   - Allows smoother multitasking

2. **GPU Acceleration Enabled**: 
   - Changed from `no` to `yes` with `host` mode
   - Uses your computer's GPU for better graphics performance

3. **Heap Size Increased**: 112M → 256M
   - More memory for Java/Kotlin applications
   - Reduces out-of-memory errors

4. **CPU Cores Reduced**: 4 → 2 cores
   - Better for systems with limited resources
   - Reduces CPU overhead

5. **Unnecessary Sensors Disabled**:
   - Disabled proximity, humidity, temperature, and pressure sensors
   - Reduces background processing overhead

## How to Use Optimized Emulators

### 1. Close any running emulators first:
```bash
# Kill all running emulators
adb kill-server
pkill -f emulator
```

### 2. Launch the optimized emulator:
```bash
# For 7-inch tablet
flutter emulators --launch Tablet_7inch

# For 10-inch tablet
flutter emulators --launch Tablet_10inch
```

### 3. Wait for full boot (30-60 seconds):
- Wait until you see the Android home screen
- Don't try to run apps until the emulator is fully loaded

### 4. Verify emulator is ready:
```bash
# Check if emulator is online
flutter devices

# Verify boot is complete
adb shell getprop sys.boot_completed
# Should return: 1
```

### 5. Run your Flutter app:
```bash
flutter run
```

## Troubleshooting

### If emulator is still slow:

1. **Close other applications** to free up system resources

2. **Check available RAM**:
   ```bash
   free -h
   ```
   Ensure you have at least 4GB free RAM

3. **Enable hardware acceleration** (if not already):
   - Check: `emulator -accel-check`
   - If KVM is not available, the emulator will be slower

4. **Reduce emulator resolution** (if needed):
   - Edit `config.ini` in `~/.android/avd/Tablet_Xinch.avd/`
   - Reduce `hw.lcd.width` and `hw.lcd.height` values

5. **Use cold boot** if emulator keeps crashing:
   ```bash
   emulator -avd Tablet_7inch -no-snapshot-load
   ```

### If "System UI isn't responding" still appears:

1. **Wait longer** - The emulator may need more time to fully initialize
2. **Restart the emulator** with a cold boot
3. **Check system resources** - Your computer may be low on RAM/CPU
4. **Try a different emulator** - Use Pixel_8a or Medium_Phone_API_36.1 for testing

## Performance Tips

- **Don't run multiple emulators** at the same time
- **Close Android Studio** if not needed (it uses significant resources)
- **Use snapshots** - The emulator saves snapshots for faster boot times
- **Monitor system resources** - Use `htop` or `top` to check CPU/RAM usage

## Configuration Files Location

- 7-inch tablet: `~/.android/avd/Tablet_7inch.avd/config.ini`
- 10-inch tablet: `~/.android/avd/Tablet_10inch.avd/config.ini`

You can manually edit these files if you need further customization.
