package com.relay.relay_translate

import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test

class LanguageDetectionTest {

    /** Fake language-id: exact-match table, everything else is `und`. Records what it was asked. */
    private class FakeDetector(private val table: Map<String, Detected>) {
        val asked = mutableListOf<String>()
        val detect: suspend (String) -> Detected = { text ->
            asked += text
            table[text] ?: Detected("und", 0f)
        }
    }

    private val batchEn = "Hey! Did you make it to London okay?\nok see u\nlol"

    @Test
    fun `short messages inherit the batch language`() = runTest {
        val fake = FakeDetector(mapOf(batchEn to Detected("en", 0.99f)))
        val sources = LanguageDetection.resolveSources(
            listOf("Hey! Did you make it to London okay?", "ok see u", "lol"), fake.detect,
        )
        assertEquals(listOf("en", "en", "en"), sources)
    }

    @Test
    fun `per-message detection is only run for long messages`() = runTest {
        val fake = FakeDetector(mapOf(batchEn to Detected("en", 0.99f)))
        LanguageDetection.resolveSources(
            listOf("Hey! Did you make it to London okay?", "ok see u", "lol"), fake.detect,
        )
        assertEquals(listOf(batchEn, "Hey! Did you make it to London okay?"), fake.asked)
    }

    @Test
    fun `confident per-message result overrides the batch language`() = runTest {
        val french = "Je suis bien arrivée, merci !"
        val batch = "Hey! Did you make it to London okay?\n$french"
        val fake = FakeDetector(
            mapOf(batch to Detected("en", 0.7f), french to Detected("fr", 0.95f)),
        )
        val sources = LanguageDetection.resolveSources(
            listOf("Hey! Did you make it to London okay?", french), fake.detect,
        )
        assertEquals(listOf("en", "fr"), sources)
    }

    @Test
    fun `low-confidence per-message result falls back to the batch language`() = runTest {
        val ambiguous = "Restaurant menu information"
        val batch = "Bonjour, comment ça va aujourd'hui ?\n$ambiguous"
        val fake = FakeDetector(
            mapOf(batch to Detected("fr", 0.8f), ambiguous to Detected("en", 0.3f)),
        )
        val sources = LanguageDetection.resolveSources(
            listOf("Bonjour, comment ça va aujourd'hui ?", ambiguous), fake.detect,
        )
        assertEquals(listOf("fr", "fr"), sources)
    }

    @Test
    fun `undetectable batch yields und unless a message is confident on its own`() = runTest {
        val german = "Ich habe den Zug leider verpasst."
        val batch = "😂\n$german"
        val fake = FakeDetector(
            mapOf(batch to Detected("und", 0f), german to Detected("de", 0.9f)),
        )
        val sources = LanguageDetection.resolveSources(listOf("😂", german), fake.detect)
        assertEquals(listOf("und", "de"), sources)
    }

    @Test
    fun `batch below confidence threshold counts as und`() = runTest {
        val fake = FakeDetector(mapOf("ok\nk" to Detected("en", 0.4f)))
        val sources = LanguageDetection.resolveSources(listOf("ok", "k"), fake.detect)
        assertEquals(listOf("und", "und"), sources)
    }

    @Test
    fun `blank texts are und and are not sent to the detector`() = runTest {
        val fake = FakeDetector(mapOf("hello there my friend" to Detected("en", 0.9f)))
        val sources = LanguageDetection.resolveSources(listOf("", "hello there my friend", "  "), fake.detect)
        assertEquals(listOf("und", "en", "und"), sources)
        assertEquals(listOf("hello there my friend", "hello there my friend"), fake.asked)
    }

    @Test
    fun `all-blank input never calls the detector`() = runTest {
        val fake = FakeDetector(emptyMap())
        val sources = LanguageDetection.resolveSources(listOf("", " "), fake.detect)
        assertEquals(listOf("und", "und"), sources)
        assertEquals(emptyList<String>(), fake.asked)
    }
}
