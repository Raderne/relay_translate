package com.relay.relay_translate

import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

/** One language-id result: BCP-47 tag (or [LanguageDetection.UND]) + confidence 0..1. */
data class Detected(val lang: String, val confidence: Float)

/**
 * Source-language rule for a batch of chat messages (see wiki `Gotcha - Short Message Language Detection`).
 *
 * Pure logic: the actual ML Kit call is injected as [detect] so this can be unit-tested on the JVM.
 *
 * 1. Detect once on the whole batch joined together — a conversation is usually one language and
 *    short messages ("ok see u") detect badly on their own.
 * 2. For messages of at least [MIN_PER_MESSAGE_CHARS] chars, also detect per message; if that result is
 *    confident (>= [MIN_CONFIDENCE]) and differs from the batch language, use it.
 * 3. Anything undetermined is [UND]; the caller returns the original text and the UI says
 *    "Couldn't detect language".
 */
object LanguageDetection {
    const val UND = "und"
    const val MIN_PER_MESSAGE_CHARS = 20
    const val MIN_CONFIDENCE = 0.5f

    /** Returns one source language per input text, same order as [texts]. Blank texts get [UND]. */
    suspend fun resolveSources(
        texts: List<String>,
        detect: suspend (String) -> Detected,
    ): List<String> = coroutineScope {
        val nonBlank = texts.filter { it.isNotBlank() }
        if (nonBlank.isEmpty()) return@coroutineScope texts.map { UND }

        val batchJob = async { detect(nonBlank.joinToString("\n")).confidentLangOrNull() }
        val perMessage = texts.map { text ->
            if (text.trim().length >= MIN_PER_MESSAGE_CHARS) async { detect(text).confidentLangOrNull() } else null
        }

        val batch = batchJob.await() ?: UND
        texts.mapIndexed { i, text ->
            if (text.isBlank()) UND else perMessage[i]?.await() ?: batch
        }
    }

    private fun Detected.confidentLangOrNull(): String? =
        lang.takeIf { it != UND && confidence >= MIN_CONFIDENCE }
}
