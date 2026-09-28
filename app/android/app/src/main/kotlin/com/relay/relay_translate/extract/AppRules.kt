package com.relay.relay_translate.extract

/**
 * Per-app view-id allow lists. Unknown packages fall back to generic heuristics.
 * Documented in wiki [[Per-App Message Rules]].
 */
object AppRules {
    private val allowByPackage: Map<String, Set<String>> = mapOf(
        "com.whatsapp" to setOf("com.whatsapp:id/message_text"),
        "com.whatsapp.w4b" to setOf("com.whatsapp:id/message_text"),
        "com.google.android.gm" to setOf(
            "com.google.android.gm:id/conversation_message_text",
            "com.google.android.gm:id/message_body",
        ),
        "com.google.android.apps.messaging" to setOf(
            "com.google.android.apps.messaging:id/message_text",
            "com.google.android.apps.messaging:id/conversation_text",
        ),
    )

    /**
     * When rules exist for [packageName], only nodes with matching [viewIdResourceName] are kept.
     * When no rules exist, returns true (generic heuristic applies elsewhere).
     */
    fun accepts(packageName: String, viewIdResourceName: String?): Boolean {
        val rules = allowByPackage[packageName] ?: return true
        if (viewIdResourceName.isNullOrBlank()) return false
        return rules.contains(viewIdResourceName)
    }

    fun hasRules(packageName: String): Boolean = allowByPackage.containsKey(packageName)
}
