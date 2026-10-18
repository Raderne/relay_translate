package com.relay.relay_translate.accessibility

import android.os.Bundle
import android.view.accessibility.AccessibilityNodeInfo
import com.relay.relay_translate.paste.PasteNode

/** Real-node side of [PasteNode]; the logic lives in `Paster` (JVM-tested). */
class AccessibilityPasteNode(private val node: AccessibilityNodeInfo) : PasteNode {
    override val isEditable: Boolean get() = node.isEditable
    override val isFocused: Boolean get() = node.isFocused
    override val isVisible: Boolean get() = node.isVisibleToUser
    override val text: String? get() = node.text?.toString()
    override val showingHint: Boolean get() = node.isShowingHintText
    override val children: List<PasteNode> by lazy {
        (0 until node.childCount).mapNotNull { i -> node.getChild(i)?.let(::AccessibilityPasteNode) }
    }

    override fun setText(text: String): Boolean = node.performAction(
        AccessibilityNodeInfo.ACTION_SET_TEXT,
        Bundle().apply { putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text) },
    )
}
