package com.relay.relay_translate

import android.content.Context

/** Target language + download prefs for native code when Flutter is not running (Phase 7–8). */
object NativeSettings {
    private const val PREFS = "relay_native_settings"

    fun sync(context: Context, targetLang: String, wifiOnlyDownloads: Boolean) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString("target_lang", targetLang)
            .putBoolean("wifi_only", wifiOnlyDownloads)
            .apply()
    }

    fun targetLang(context: Context): String =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString("target_lang", "fr") ?: "fr"

    fun wifiOnly(context: Context): Boolean =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean("wifi_only", true)
}
