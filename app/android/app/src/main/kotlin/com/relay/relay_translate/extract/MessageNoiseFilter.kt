package com.relay.relay_translate.extract

/**
 * Drops timestamps, emoji-only crumbs, and other non-message noise from extracted text.
 */
object MessageNoiseFilter {
    private val timestamp = Regex("^\\d{1,2}:\\d{2}$")

    fun isNoise(text: String): Boolean {
        val t = text.trim()
        if (t.length < 2) return true
        if (timestamp.matches(t)) return true
        if (isSingleEmojiOrSymbol(t)) return true
        return false
    }

    private fun isSingleEmojiOrSymbol(t: String): Boolean {
        if (t.isEmpty()) return false
        if (t.codePoints().count() != 1L) return false
        val cp = t.codePoints().findFirst().orElse(0)
        val type = Character.getType(cp)
        return type == Character.OTHER_SYMBOL.toInt() ||
            type == Character.SURROGATE.toInt() ||
            type == Character.OTHER_PUNCTUATION.toInt()
    }
}
