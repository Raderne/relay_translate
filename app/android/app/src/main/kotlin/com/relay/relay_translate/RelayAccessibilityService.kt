package com.relay.relay_translate

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/**
 * Empty until Phase 8. Declared now so onboarding can send the user to Android's
 * accessibility screen and so [PermissionsChannel] can see the service once enabled.
 * `isAccessibilityTool` stays false — see the Play accessibility gotcha.
 */
class RelayAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}
}
