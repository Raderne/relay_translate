package com.relay.relay_translate.accessibility

import android.view.accessibility.AccessibilityEvent

/**
 * When the translated boxes must go because the messages under them moved. Content changes are
 * ignored: chat apps fire them constantly (read receipts, timestamps), and boxes vanished right after
 * appearing. Relay's own windows (bubble, toasts, detail sheet) never count.
 */
object OverlayInvalidation {
    fun shouldClear(eventType: Int, eventPackage: String?, ownPackage: String, shownPackage: String?): Boolean {
        if (eventPackage == null || eventPackage == ownPackage) return false
        return when (eventType) {
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> eventPackage == shownPackage
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> true
            else -> false
        }
    }
}
