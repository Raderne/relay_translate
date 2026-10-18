package com.relay.relay_translate

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import com.relay.relay_translate.bubble.BubblePrefs
import com.relay.relay_translate.bubble.BubbleService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `relay/overlay` (Phase 7). Dart pushes bubble settings with `apply`; native is the source of truth
 * for what changed while Flutter was away (drag, hint, Hide), which Dart pulls with `state`.
 */
class OverlayChannel(private val activity: Activity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "relay/overlay").also { it.setMethodCallHandler(this) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "apply" -> {
                val a = call.arguments as Map<*, *>
                val on = a["on"] as Boolean
                BubblePrefs.write(
                    activity,
                    BubblePrefs.Values(
                        on = on,
                        size = a["size"] as String,
                        snap = a["snap"] as Boolean,
                        x = (a["x"] as Number).toFloat(),
                        y = (a["y"] as Number).toFloat(),
                        hintSeen = a["hintSeen"] as Boolean,
                    ),
                )
                when {
                    !on -> {
                        BubbleService.stop(activity)
                        result.success(false)
                    }
                    !Settings.canDrawOverlays(activity) -> result.success(false)
                    else -> {
                        if (BubbleService.instance == null) askForNotifications()
                        BubbleService.start(activity)
                        result.success(true)
                    }
                }
            }
            "state" -> {
                if (!BubblePrefs.exists(activity)) return result.success(null)
                val v = BubblePrefs.read(activity)
                result.success(mapOf("on" to v.on, "x" to v.x.toDouble(), "y" to v.y.toDouble(), "hintSeen" to v.hintSeen))
            }
            "takeRoute" -> result.success(MainActivity.takePendingRoute())
            else -> result.notImplemented()
        }
    }

    /** Android 13+: without it the "Relay bubble is on" notification (and its Hide action) is not shown. */
    private fun askForNotifications() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return
        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private companion object {
        const val REQUEST_NOTIFICATIONS = 7
    }
}
