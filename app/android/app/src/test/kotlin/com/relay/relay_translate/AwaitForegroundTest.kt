package com.relay.relay_translate

import com.relay.relay_translate.paste.awaitForeground
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AwaitForegroundTest {
    @Test
    fun returnsOnceTheAppIsBackInFront() = runTest {
        val seen = ArrayDeque(listOf("com.relay.relay_translate.beta", "com.relay.relay_translate.beta", "com.whatsapp"))
        val ok = awaitForeground("com.whatsapp", timeoutMs = 2000, pollMs = 100) { seen.removeFirstOrNull() ?: "com.whatsapp" }
        assertTrue(ok)
        assertEquals(200L, currentTime)
    }

    @Test
    fun givesUpAfterTheTimeout() = runTest {
        val ok = awaitForeground("com.whatsapp", timeoutMs = 1000, pollMs = 100) { "com.android.launcher3" }
        assertFalse(ok)
        assertEquals(1000L, currentTime)
    }
}
