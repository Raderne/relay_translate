package com.relay.relay_translate

import com.relay.relay_translate.extract.MessageNoiseFilter
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MessageNoiseFilterTest {
    @Test
    fun rejectsTimestampsSingleCharAndEmojiOnly() {
        assertTrue(MessageNoiseFilter.isNoise("10:02"))
        assertTrue(MessageNoiseFilter.isNoise("9:05"))
        assertTrue(MessageNoiseFilter.isNoise("a"))
        assertTrue(MessageNoiseFilter.isNoise("👍"))
    }

    @Test
    fun acceptsRealChatText() {
        assertFalse(MessageNoiseFilter.isNoise("Hey! Did you make it to London okay?"))
        assertFalse(MessageNoiseFilter.isNoise("ok"))
    }
}
