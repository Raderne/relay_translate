package com.relay.relay_translate

import com.relay.relay_translate.extract.DropTargetSelector
import com.relay.relay_translate.extract.Rect
import com.relay.relay_translate.extract.ScreenMessage
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DropTargetSelectorTest {
    private fun msg(id: String, l: Int, t: Int, r: Int, b: Int) =
        ScreenMessage(id, "text$id", Rect(l, t, r, b))

    @Test
    fun returnsNullWhenNothingHit() {
        val list = listOf(msg("a", 0, 0, 10, 10))
        assertNull(DropTargetSelector.select(list, 50, 50))
    }

    @Test
    fun prefersSmallestContainingBounds() {
        val outer = msg("o", 0, 0, 100, 100)
        val inner = msg("i", 40, 40, 60, 60)
        val hit = DropTargetSelector.select(listOf(outer, inner), 50, 50)
        assertEquals("i", hit?.id)
    }
}
