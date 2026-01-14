package com.odatransportation.app

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15+ (API 35+)
        // This ensures proper display on devices with edge-to-edge enabled by default
        if (Build.VERSION.SDK_INT >= 35) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        super.onCreate(savedInstanceState)
    }
}
