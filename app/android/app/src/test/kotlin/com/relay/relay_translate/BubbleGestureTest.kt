package com.relay.relay_translate

import com.relay.relay_translate.bubble.BubbleGesture
import com.relay.relay_translate.bubble.BubblePhase
import com.relay.relay_translate.bubble.BubbleTokens
import com.relay.relay_translate.bubble.Box
import com.relay.relay_translate.bubble.Pt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Mirrors `test/bubble/bubble_controller_test.dart` case for case. */
class BubbleGestureTest {
    private fun controller(
        x: Float = 100f,
        y: Float = 200f,
        onTapMenu: (() -> Unit)? = null,
        onTranslateAll: (() -> Unit)? = null,
        onTranslateOne: ((String?) -> Unit)? = null,
    ) = BubbleGesture(
        sizeCode = "M",
        snapEnabled = true,
        initialX = x,
        initialY = y,
        onTapMenu = onTapMenu,
        onTranslateAll = onTranslateAll,
        onTranslateOne = onTranslateOne,
    ).also { it.setViewport(400f, 800f) }

    private val down = Pt(120f, 220f)
    private fun Pt.plus(dx: Float) = Pt(x + dx, y)

    @Test
    fun tapOpensMenu() {
        var menu = false
        val c = controller(onTapMenu = { menu = true })
        c.pointerDown(down)
        c.pointerUp(100, down)
        assertTrue(menu)
        assertEquals(BubblePhase.MENU_OPEN, c.phase)
    }

    @Test
    fun hold550TriggersTranslateAll() {
        var all = false
        val c = controller(onTranslateAll = { all = true })
        c.pointerDown(down)
        c.tickPressing(BubbleTokens.holdMs)
        assertTrue(all)
        assertEquals(BubblePhase.IDLE, c.phase)
    }

    @Test
    fun pointerUpAfterHoldElapsedTriggersTranslateAll() {
        var all = false
        val c = controller(onTranslateAll = { all = true })
        c.pointerDown(down)
        c.pointerUp(BubbleTokens.holdMs, down)
        assertTrue(all)
    }

    @Test
    fun fivePxStaysPressingSevenPxDrags() {
        val c = controller()
        c.pointerDown(down)
        c.pointerMove(down.plus(5f))
        assertEquals(BubblePhase.PRESSING, c.phase)
        c.pointerMove(down.plus(7f))
        assertEquals(BubblePhase.DRAGGING, c.phase)
    }

    @Test
    fun snapLeftWhenCentreInLeftHalf() {
        val c = controller(x = 20f)
        val start = Pt(30f, 220f)
        c.pointerDown(start)
        c.pointerMove(start.plus(8f))
        c.pointerUp(100, start.plus(8f))
        assertEquals(BubbleTokens.snapInset, c.x)
    }

    @Test
    fun snapRightWhenCentreInRightHalf() {
        val c = controller(x = 300f)
        val start = Pt(320f, 220f)
        c.pointerDown(start)
        c.pointerMove(start.plus(8f))
        c.pointerUp(100, start.plus(8f))
        assertEquals(400f - c.diameter - BubbleTokens.snapInset, c.x)
    }

    @Test
    fun clampKeepsBubbleInsideViewport() {
        val c = controller(x = -50f, y = 10f)
        assertTrue(c.y >= BubbleTokens.topInset)
        assertTrue(c.x >= 0f)
    }

    @Test
    fun dropWithNoTargetPassesNullId() {
        var dropped: String? = "unset"
        val c = controller(onTranslateOne = { dropped = it })
        c.setIncomingTargets(emptyMap())
        c.pointerDown(down)
        c.pointerMove(down.plus(8f))
        c.pointerUp(100, down.plus(8f))
        assertNull(dropped)
    }

    @Test
    fun hitTestOnlyIncomingRects() {
        var id = "unset"
        val c = controller(onTranslateOne = { id = it ?: "null" })
        val hit = Pt(50f, 50f)
        c.setIncomingTargets(mapOf("m3" to Box(40f, 40f, 120f, 80f)))
        c.pointerDown(hit)
        c.pointerMove(hit.plus(8f))
        assertEquals("m3", c.targetMessageId)
        c.pointerUp(100, hit.plus(8f))
        assertEquals("m3", id)
    }

    @Test
    fun menuOpensAwayFromRightEdge() {
        val c = controller(x = 300f, y = 10f)
        val origin = c.menuOrigin()
        assertEquals(300f - BubbleTokens.menuWidth - 8, origin.x)
        assertEquals(BubbleTokens.menuTopMin, origin.y)
    }
}
