#!/bin/bash

# Optimized 16KB Emulator Launch Script
# This script launches the 16KB emulator with performance optimizations

echo "🚀 Launching 16KB Emulator with optimizations..."

# Kill any existing emulator processes
echo "Cleaning up existing emulator processes..."
pkill -9 -f emulator 2>/dev/null
pkill -9 -f qemu 2>/dev/null
adb kill-server 2>/dev/null
sleep 2

# Set Android SDK path
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin

# Launch emulator with optimizations
echo "Starting emulator with optimized settings..."
echo "Note: First launch will be slower. Subsequent launches will use snapshots."
$ANDROID_HOME/emulator/emulator \
  -avd Pixel_8_16KB \
  -gpu swiftshader_indirect \
  -no-audio \
  -memory 1536 \
  -cores 2 \
  -netspeed full \
  -netdelay none \
  > /tmp/emulator.log 2>&1 &

EMULATOR_PID=$!
echo "Emulator started with PID: $EMULATOR_PID"
echo "Logs are being written to: /tmp/emulator.log"

# Wait for emulator to boot
echo "Waiting for emulator to boot (this may take 60-90 seconds)..."
echo "Please be patient..."

# Wait for ADB to detect device
for i in {1..90}; do
  sleep 1
  if adb devices | grep -q "emulator.*device"; then
    echo "✅ Emulator detected!"
    break
  fi
  if [ $((i % 10)) -eq 0 ]; then
    echo "Still waiting... ($i seconds)"
  fi
done

# Wait for boot to complete
echo "Waiting for Android to fully boot..."
for i in {1..60}; do
  sleep 1
  if adb shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; then
    echo "✅ Android boot completed!"
    break
  fi
  if [ $((i % 10)) -eq 0 ]; then
    echo "Still booting... ($i seconds)"
  fi
done

# Verify 16KB page size
PAGE_SIZE=$(adb shell getconf PAGE_SIZE 2>/dev/null)
if [ "$PAGE_SIZE" = "16384" ]; then
  echo "✅ Verified: Using 16KB page size ($PAGE_SIZE bytes)"
else
  echo "⚠️  Warning: Page size is $PAGE_SIZE bytes (expected 16384)"
fi

# Show device info
echo ""
echo "📱 Emulator Status:"
adb devices
echo ""
echo "✅ Emulator is ready!"
echo "You can now run: flutter run -d emulator-5554"
echo ""
echo "To view emulator logs: tail -f /tmp/emulator.log"
echo "To stop emulator: pkill -f emulator"
