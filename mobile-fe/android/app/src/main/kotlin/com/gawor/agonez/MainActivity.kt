package com.gawor.agonez

import android.app.UiModeManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "agonez/system_ui")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setNightMode" -> {
                        setApplicationNightMode(call.arguments as? String)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Persists the in-app theme with Android. The system splash is drawn
     * before any Dart runs and cannot read the app's settings database, but
     * from Android 12 it honours the application night mode on the next
     * launch. Older versions keep following the system theme.
     */
    private fun setApplicationNightMode(themeMode: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val nightMode = when (themeMode) {
            "light" -> UiModeManager.MODE_NIGHT_NO
            "dark" -> UiModeManager.MODE_NIGHT_YES
            else -> UiModeManager.MODE_NIGHT_AUTO
        }
        getSystemService(UiModeManager::class.java)?.setApplicationNightMode(nightMode)
    }
}
