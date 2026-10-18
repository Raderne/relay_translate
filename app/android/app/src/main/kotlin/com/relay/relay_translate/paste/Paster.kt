package com.relay.relay_translate.paste

/** The bits of an accessibility node pasting needs; faked in JVM tests (`PasterTest`). */
interface PasteNode {
    val isEditable: Boolean
    val isFocused: Boolean
    val isVisible: Boolean
    val text: String?
    /** Android 8+: `text` is the hint ("Message"), not a draft. */
    val showingHint: Boolean
    val children: List<PasteNode>
    /** `ACTION_SET_TEXT`. False when the app refuses it. */
    fun setText(text: String): Boolean
}

/**
 * Puts a reply into the other app's message box (Phase 9). Never presses Send — the user always sends.
 * Wiki: [[Screens and Flows]] → cross-app reply.
 */
object Paster {
    /** True when the reply landed in a field; false → caller falls back to the clipboard. */
    fun paste(root: PasteNode?, reply: String): Boolean {
        val target = findTarget(root) ?: return false
        return target.setText(merge(target.text, target.showingHint, reply))
    }

    /** Focused editable field first, else the first visible editable one (depth-first). */
    fun findTarget(root: PasteNode?): PasteNode? {
        if (root == null) return null
        val editables = mutableListOf<PasteNode>()
        collect(root, editables)
        return editables.firstOrNull { it.isFocused } ?: editables.firstOrNull()
    }

    /** v1: replace an empty field, otherwise append after a space. */
    fun merge(existing: String?, showingHint: Boolean, reply: String): String {
        val draft = if (showingHint) "" else existing.orEmpty().trimEnd()
        return if (draft.isBlank()) reply else "$draft $reply"
    }

    private fun collect(node: PasteNode, out: MutableList<PasteNode>) {
        if (node.isEditable && node.isVisible) out += node
        node.children.forEach { collect(it, out) }
    }
}
