package com.example.mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val HEALTH_SETTINGS_CHANNEL =
            "com.prana.health/settings"

        private const val OPEN_HEALTH_SETTINGS_METHOD =
            "openHealthSettings"

        private const val HEALTH_CONNECT_PACKAGE =
            "com.google.android.apps.healthdata"

        private const val HEALTH_HOME_SETTINGS_ACTION =
            "android.health.connect.action.HEALTH_HOME_SETTINGS"

        private const val LEGACY_HEALTH_CONNECT_SETTINGS_ACTION =
            "androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HEALTH_SETTINGS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                OPEN_HEALTH_SETTINGS_METHOD -> {
                    result.success(openHealthSettings())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openHealthSettings(): Boolean {
        val action =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                HEALTH_HOME_SETTINGS_ACTION
            } else {
                LEGACY_HEALTH_CONNECT_SETTINGS_ACTION
            }

        try {
            startActivity(Intent(action))
            return true
        } catch (_: ActivityNotFoundException) {
            // Fall through to the legacy Health Connect app.
        }

        val fallbackIntent =
            packageManager.getLaunchIntentForPackage(
                HEALTH_CONNECT_PACKAGE
            ) ?: return false

        return try {
            startActivity(fallbackIntent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}