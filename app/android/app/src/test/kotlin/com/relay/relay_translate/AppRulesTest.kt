package com.relay.relay_translate

import com.relay.relay_translate.extract.AppRules
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AppRulesTest {
    private val messages = "com.google.android.apps.messaging"

    @Test
    fun acceptsFullViewIds() {
        assertTrue(AppRules.accepts(messages, "com.google.android.apps.messaging:id/message_text", "A said Hi"))
    }

    // Google Messages is Compose: uiautomator shows resource-id="message_text" with no package prefix.
    @Test
    fun acceptsBareComposeIds() {
        assertTrue(AppRules.accepts(messages, "message_text", "A said Hi"))
    }

    @Test
    fun rejectsOtherIdsAndMissingIds() {
        assertFalse(AppRules.accepts(messages, "conversation_title"))
        assertFalse(AppRules.accepts(messages, "com.google.android.apps.messaging:id/conversation_title"))
        assertFalse(AppRules.accepts(messages, null))
    }

    @Test
    fun unknownAppsFallBackToHeuristics() {
        assertTrue(AppRules.accepts("org.example.chat", null))
    }

    // Messages info lines ("Texting with 555-1234 (SMS/MMS)") share the id but have no description;
    // real bubbles always have one ("555-1234 said …", localized).
    @Test
    fun messagesNeedsAContentDescription() {
        assertTrue(AppRules.accepts(messages, "message_text", contentDescription = "555-1234 said  Hi 4:03 PM ."))
        assertFalse(AppRules.accepts(messages, "message_text", contentDescription = ""))
        assertFalse(AppRules.accepts(messages, "message_text", contentDescription = null))
    }

    @Test
    fun otherAppsDoNotNeedADescription() {
        assertTrue(AppRules.accepts("com.whatsapp", "com.whatsapp:id/message_text", contentDescription = null))
    }
}
