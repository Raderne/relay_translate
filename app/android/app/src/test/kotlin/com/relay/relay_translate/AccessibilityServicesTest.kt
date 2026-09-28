package com.relay.relay_translate

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AccessibilityServicesTest {
    private val flat = "com.relay.relay_translate.beta/com.relay.relay_translate.RelayAccessibilityService"
    private val short = "com.relay.relay_translate.beta/.RelayAccessibilityService"

    @Test
    fun `empty list is not enabled`() {
        assertFalse(AccessibilityServices.contains(null, flat, short))
        assertFalse(AccessibilityServices.contains("", flat, short))
    }

    @Test
    fun `matches the flattened component among others`() {
        val list = "com.other/.Service:$flat"
        assertTrue(AccessibilityServices.contains(list, flat, short))
    }

    @Test
    fun `matches the short component name`() {
        assertTrue(AccessibilityServices.contains(short, flat, short))
    }

    @Test
    fun `a different service does not match`() {
        assertFalse(AccessibilityServices.contains("com.other/.Service", flat, short))
    }
}
