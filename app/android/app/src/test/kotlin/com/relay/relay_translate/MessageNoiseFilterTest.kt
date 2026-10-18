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

    // Seen on Google Messages (2026-10-18): the day divider "4:03 PM" was translated and logged.
    @Test
    fun rejectsTwelveHourTimestamps() {
        assertTrue(MessageNoiseFilter.isNoise("4:03 PM"))
        assertTrue(MessageNoiseFilter.isNoise("11:45 am"))
        assertTrue(MessageNoiseFilter.isNoise("9:05PM"))
        assertFalse(MessageNoiseFilter.isNoise("4:03 PM works for me"))
    }
}
