package com.relay.relay_translate

/**
 * Whether [component] (either [android.content.ComponentName.flattenToString] or the short form)
 * is in the colon-separated `ENABLED_ACCESSIBILITY_SERVICES` value.
 */
internal object AccessibilityServices {
    fun contains(enabledList: String?, flat: String, short: String): Boolean {
        if (enabledList.isNullOrBlank()) return false
        return enabledList.split(':').any { entry ->
            entry.equals(flat, ignoreCase = true) || entry.equals(short, ignoreCase = true)
        }
    }
}
