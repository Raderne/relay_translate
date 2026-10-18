package com.relay.relay_translate.history

import com.relay.relay_translate.Translator

/**
 * History rows for one accessibility translate call (mirror of what `ChatterSession` logs).
 * Phase 10 metrics: [elapsedMs] is dropped when the call downloaded a model, and the beta also logs
 * undetected (`und`) messages so the detection-failure rate is measurable.
 */
object HistoryRows {
    fun build(
        sources: List<String>,
        results: List<Translator.Result>,
        appPackage: String,
        appLabel: String,
        targetLang: String,
        elapsedMs: Long,
        beta: Boolean,
    ): List<HistoryEventBuffer.HistoryItem> = sources.zip(results).mapNotNull { (src, res) ->
        val und = res.source == "und"
        if (und && !beta) return@mapNotNull null
        HistoryEventBuffer.HistoryItem(
            appPackage = appPackage,
            appLabel = appLabel,
            src = src,
            tr = if (und) src else res.text,
            srcLang = res.source,
            targetLang = targetLang,
            ms = if (res.downloaded) null else elapsedMs,
        )
    }
}
