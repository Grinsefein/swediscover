#!/bin/bash
# Script to pull logcat logs from Android device to workspace/logs/logcat.log

echo "Pulling logcat logs from Android device..."

# Get the internal log file from the app's private storage
adb pull /data/data/com.lateinlabs.swediscover/files/logcat.log /workspace/logs/logcat.log 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Could not pull from internal storage. Trying external storage..."
    # Try external storage as fallback
    adb pull /sdcard/Android/data/com.lateinlabs.swediscover/files/swediscover_logcat.log /workspace/logs/logcat.log 2>/dev/null
fi

if [ $? -eq 0 ]; then
    echo "✓ Logcat logs saved to /workspace/logs/logcat.log"
    echo "File size: $(wc -l /workspace/logs/logcat.log | awk '{print $1}') lines"
else
    echo "✗ Failed to pull logcat logs. Make sure:"
    echo "  1. Device is connected (run: adb devices)"
    echo "  2. App has been running on the device"
    echo "  3. You have proper permissions"
fi
