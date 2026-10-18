package com.relay.relay_translate

import com.relay.relay_translate.history.HistoryRows
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Phase 10: history rows written by the accessibility path must keep the beta metrics honest. */
class HistoryRowsTest {
    private val hi = "Hey! Are you free tonight?"
    private val ok = "ok"

    private fun build(results: List<Translator.Result>, beta: Boolean) = HistoryRows.build(
        sources = listOf(hi, ok),
        results = results,
        appPackage = "com.whatsapp",
        appLabel = "WhatsApp",
        targetLang = "fr",
        elapsedMs = 420,
        beta = beta,
    )

    @Test
    fun translatedRowsCarryTheLatency() {
        val rows = build(listOf(Translator.Result("Tu es libre ?", "en"), Translator.Result("ok", "en")), beta = false)
        assertEquals(2, rows.size)
        assertEquals("Tu es libre ?", rows[0].tr)
        assertEquals("en", rows[0].srcLang)
        assertEquals("WhatsApp", rows[0].appLabel)
        assertEquals(420L, rows[0].ms)
    }

    @Test
    fun aCallThatDownloadedAModelLogsNoLatency() {
        val rows = build(listOf(Translator.Result("Tu es libre ?", "en", downloaded = true), Translator.Result("ok", "en", downloaded = true)), beta = false)
        assertNull(rows[0].ms)
        assertNull(rows[1].ms)
    }

    @Test
    fun undetectedIsSkippedInReleaseButLoggedInBeta() {
        val results = listOf(Translator.Result("Tu es libre ?", "en"), Translator.Result(ok, "und"))
        assertEquals(listOf(hi), build(results, beta = false).map { it.src })
        val beta = build(results, beta = true)
        assertEquals(listOf(hi, ok), beta.map { it.src })
        assertEquals("und", beta[1].srcLang)
        assertEquals(ok, beta[1].tr)
    }
}
