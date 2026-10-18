package com.relay.relay_translate

import android.view.accessibility.AccessibilityEvent.TYPE_VIEW_SCROLLED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
import android.view.accessibility.AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
import com.relay.relay_translate.accessibility.OverlayInvalidation
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OverlayInvalidationTest {
    private val own = "com.relay.relay_translate.beta"
    private val chat = "com.google.android.apps.messaging"

    private fun clears(type: Int, pkg: String?) = OverlayInvalidation.shouldClear(type, pkg, ownPackage = own, shownPackage = chat)

    // Seen on the emulator: Messages fires content changes right after the boxes appear.
    @Test
    fun contentChangesNeverClear() {
        assertFalse(clears(TYPE_WINDOW_CONTENT_CHANGED, chat))
    }

    @Test
    fun scrollInTheTranslatedAppClears() {
        assertTrue(clears(TYPE_VIEW_SCROLLED, chat))
    }

    @Test
    fun newScreenOrAnotherAppClears() {
        assertTrue(clears(TYPE_WINDOW_STATE_CHANGED, chat))
        assertTrue(clears(TYPE_WINDOW_STATE_CHANGED, "com.android.chrome"))
    }

    @Test
    fun relaysOwnWindowsNeverClear() {
        assertFalse(clears(TYPE_WINDOW_STATE_CHANGED, own))
        assertFalse(clears(TYPE_VIEW_SCROLLED, own))
    }

    @Test
    fun scrollInSomeOtherWindowDoesNotClear() {
        assertFalse(clears(TYPE_VIEW_SCROLLED, "com.android.systemui"))
    }
}
