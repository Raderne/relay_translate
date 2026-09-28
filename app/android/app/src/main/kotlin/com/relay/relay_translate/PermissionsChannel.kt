package com.relay.relay_translate

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * `relay/permissions` — overlay + accessibility status, and the intents that open
 * the real Android screens. `onboarded` is a file in `filesDir` until Phase 4's
 * sqflite `settings` row replaces it. Dart never asks Android itself.
 *
 * - `status` → `{overlay, accessibility, onboarded}`
 * - `openOverlay` / `openAccessibility` → null
 * - `setOnboarded` → null
 */
class PermissionsChannel(
    private val activity: FlutterActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME).also { it.setMethodCallHandler(this) }
    private val onboardedFile = File(activity.filesDir, ONBOARDED_FILE)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(
                mapOf(
                    "overlay" to Settings.canDrawOverlays(activity),
                    "accessibility" to accessibilityEnabled(),
                    "onboarded" to onboardedFile.exists(),
                ),
            )
            "openOverlay" -> {
                openOverlay()
                result.success(null)
            }
            "openAccessibility" -> {
                openAccessibility()
                result.success(null)
            }
            "setOnboarded" -> {
                onboardedFile.writeText("1")
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun accessibilityEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            activity.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        )
        val component = ComponentName(activity, RelayAccessibilityService::class.java)
        return AccessibilityServices.contains(
            enabled,
            component.flattenToString(),
            component.flattenToShortString(),
        )
    }

    private fun openOverlay() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${activity.packageName}"),
        )
        try {
            activity.startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
        }
    }

    private fun openAccessibility() {
        activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    private companion object {
        const val NAME = "relay/permissions"
        const val ONBOARDED_FILE = "onboarded"
    }
}
