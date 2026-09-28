package com.relay.relay_translate.extract

/**
 * Plain tree node for extraction logic (unit-tested without [android.view.accessibility.AccessibilityNodeInfo]).
 */
data class ExtractNode(
    val text: String?,
    val contentDescription: String?,
    val viewId: String?,
    val className: String?,
    val bounds: Rect,
    val visibleToUser: Boolean,
    val editable: Boolean,
    val children: List<ExtractNode> = emptyList(),
) {
    fun displayText(): String? {
        val t = text?.trim()?.takeIf { it.isNotEmpty() }
        if (t != null) return t
        return contentDescription?.trim()?.takeIf { it.isNotEmpty() }
    }

    fun isTextViewLike(): Boolean {
        val cn = className ?: return false
        return cn.contains("TextView") || cn.contains("Button") || cn.contains("EditText")
    }
}
