package com.relay.relay_translate

import com.relay.relay_translate.paste.PasteNode
import com.relay.relay_translate.paste.Paster
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PasterTest {
    private class Fake(
        val name: String,
        override val isEditable: Boolean = false,
        override val isFocused: Boolean = false,
        override val isVisible: Boolean = true,
        override val text: String? = null,
        override val showingHint: Boolean = false,
        override val children: List<PasteNode> = emptyList(),
        private val accepts: Boolean = true,
    ) : PasteNode {
        var setTo: String? = null
        override fun setText(text: String): Boolean {
            if (!accepts) return false
            setTo = text
            return true
        }
    }

    private fun root(vararg children: PasteNode) = Fake("root", children = children.toList())

    @Test
    fun prefersFocusedEditableOverEarlierOne() {
        val search = Fake("search", isEditable = true)
        val composer = Fake("composer", isEditable = true, isFocused = true)
        assertEquals("composer", (Paster.findTarget(root(search, composer)) as Fake).name)
    }

    @Test
    fun fallsBackToFirstVisibleEditableDepthFirst() {
        val hidden = Fake("hidden", isEditable = true, isVisible = false)
        val nested = Fake("nested", isEditable = true)
        val later = Fake("later", isEditable = true)
        val group = Fake("group", children = listOf(nested))
        assertEquals("nested", (Paster.findTarget(root(hidden, group, later)) as Fake).name)
    }

    @Test
    fun noEditableMeansNoTarget() {
        assertNull(Paster.findTarget(root(Fake("label", text = "Hi"))))
        assertNull(Paster.findTarget(null))
    }

    @Test
    fun mergeReplacesEmptyOrHintAndAppendsToDraft() {
        assertEquals("Hello", Paster.merge(existing = null, showingHint = false, reply = "Hello"))
        assertEquals("Hello", Paster.merge(existing = "  ", showingHint = false, reply = "Hello"))
        assertEquals("Hello", Paster.merge(existing = "Message", showingHint = true, reply = "Hello"))
        assertEquals("ok Hello", Paster.merge(existing = "ok", showingHint = false, reply = "Hello"))
        assertEquals("ok Hello", Paster.merge(existing = "ok ", showingHint = false, reply = "Hello"))
    }

    @Test
    fun pasteSetsMergedTextOnTarget() {
        val composer = Fake("composer", isEditable = true, isFocused = true, text = "ok")
        assertTrue(Paster.paste(root(composer), "Hello"))
        assertEquals("ok Hello", composer.setTo)
    }

    @Test
    fun pasteFailsWhenNoFieldOrSetTextRefused() {
        assertFalse(Paster.paste(root(Fake("label")), "Hello"))
        val stubborn = Fake("composer", isEditable = true, accepts = false)
        assertFalse(Paster.paste(root(stubborn), "Hello"))
    }
}
