package com.relay.relay_translate.bubble

import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/*
 * Line-for-line port of `app/lib/bubble/bubble_controller.dart` + `bubble_tokens.dart`.
 * CLAUDE.md rule 3: change both in the same commit. Units are dp, origin = screen top-left.
 * Wiki: [[Bubble Interaction Model]].
 */

object BubbleTokens {
    const val holdMs = 550
    const val moveThreshold = 6f
    const val translateAllMinMs = 700
    const val progressBarMs = 650
    const val flashMs = 900
    const val snapAnimMs = 250
    const val menuWidth = 190f
    const val hintWidth = 200f
    const val menuTopMin = 40f
    const val menuTopMaxOffset = 230f
    const val snapInset = 6f
    const val topInset = 36f
    const val bottomInset = 30f
    const val scalePressing = 0.94f
    const val scaleDragging = 1.08f
    const val scaleTarget = 1.18f
    const val ringStroke = 2f
    const val ringPad = 4f
    const val iconFraction = 0.46f
}

/** `bubbleDiameter` in `settings_store.dart`. */
fun bubbleDiameter(size: String): Int = when (size) {
    "S" -> 44
    "M" -> 52
    "L" -> 60
    else -> 52
}

enum class BubblePhase { IDLE, PRESSING, DRAGGING, MENU_OPEN }

data class Pt(val x: Float, val y: Float) {
    operator fun minus(o: Pt) = Pt(x - o.x, y - o.y)
    val distance: Float get() = hypot(x, y)
}

data class Box(val left: Float, val top: Float, val right: Float, val bottom: Float) {
    // Same as Flutter's Rect.contains: right/bottom exclusive.
    fun contains(p: Pt) = p.x >= left && p.x < right && p.y >= top && p.y < bottom
}

class BubbleGesture(
    var sizeCode: String,
    var snapEnabled: Boolean,
    initialX: Float,
    initialY: Float,
    private val onTapMenu: (() -> Unit)? = null,
    private val onTranslateAll: (() -> Unit)? = null,
    private val onTranslateOne: ((String?) -> Unit)? = null,
    private val onInteraction: (() -> Unit)? = null,
    private val onPositionPersist: ((Float, Float) -> Unit)? = null,
    private val onChanged: (() -> Unit)? = null, // notifyListeners()
) {
    var phase = BubblePhase.IDLE
        private set
    var targetMessageId: String? = null
        private set
    var x = initialX
        private set
    var y = initialY
        private set
    private var downGlobal: Pt? = null
    private var holdFired = false

    val diameter: Float get() = bubbleDiameter(sizeCode).toFloat()

    private var viewportW = 0f
    private var viewportH = 0f
    private var incomingTargets: Map<String, Box> = emptyMap()

    fun setViewport(width: Float, height: Float) {
        if (viewportW == width && viewportH == height) return
        viewportW = width
        viewportH = height
        clampPosition()
        notifyListeners()
    }

    /** The system overlay never calls this: reading targets while dragging would break the privacy rule. */
    fun setIncomingTargets(targets: Map<String, Box>) {
        incomingTargets = targets
    }

    fun syncPosition(x: Float, y: Float) {
        this.x = x
        this.y = y
        clampPosition()
        notifyListeners()
    }

    fun dismissMenu() {
        if (phase == BubblePhase.MENU_OPEN) {
            phase = BubblePhase.IDLE
            notifyListeners()
        }
    }

    fun pointerDown(global: Pt) {
        onInteraction?.invoke()
        dismissMenu()
        downGlobal = global
        holdFired = false
        targetMessageId = null
        phase = BubblePhase.PRESSING
        notifyListeners()
    }

    fun pointerMove(global: Pt) {
        if (phase != BubblePhase.PRESSING && phase != BubblePhase.DRAGGING) return
        val down = downGlobal ?: return

        val delta = global - down
        if (phase == BubblePhase.PRESSING && delta.distance >= BubbleTokens.moveThreshold) {
            phase = BubblePhase.DRAGGING
        }
        if (phase == BubblePhase.DRAGGING) {
            x = global.x - diameter / 2
            y = global.y - diameter / 2
            clampPosition()
            targetMessageId = hitTest(global)
            notifyListeners()
        }
    }

    fun pointerUp(elapsedMs: Int, global: Pt) {
        val down = downGlobal ?: return
        val moved = (global - down).distance

        if (phase == BubblePhase.PRESSING) {
            if (!holdFired && elapsedMs >= BubbleTokens.holdMs) {
                holdFired = true
                onTranslateAll?.invoke()
                finishPointer()
                return
            }
            if (!holdFired && elapsedMs < BubbleTokens.holdMs && moved < BubbleTokens.moveThreshold) {
                phase = BubblePhase.MENU_OPEN
                onTapMenu?.invoke()
                notifyListeners()
                return
            }
        }

        if (phase == BubblePhase.DRAGGING) {
            if (snapEnabled) applySnap()
            val id = targetMessageId
            onTranslateOne?.invoke(id)
            onPositionPersist?.invoke(x, y)
            finishPointer()
            return
        }

        finishPointer()
    }

    /** Call on each frame while [phase] is [BubblePhase.PRESSING]. */
    fun tickPressing(elapsedMs: Int) {
        if (phase != BubblePhase.PRESSING || holdFired) return
        if (elapsedMs >= BubbleTokens.holdMs) {
            holdFired = true
            onTranslateAll?.invoke()
            finishPointer()
        }
    }

    fun ringProgress(elapsedMs: Int): Float {
        if (phase != BubblePhase.PRESSING) return 0f
        return min(1f, elapsedMs.toFloat() / BubbleTokens.holdMs)
    }

    val scale: Float
        get() = when (phase) {
            BubblePhase.PRESSING -> BubbleTokens.scalePressing
            BubblePhase.DRAGGING -> if (targetMessageId != null) BubbleTokens.scaleTarget else BubbleTokens.scaleDragging
            else -> 1f
        }

    val fillAccent: Boolean get() = phase == BubblePhase.DRAGGING && targetMessageId != null

    private fun finishPointer() {
        phase = BubblePhase.IDLE
        targetMessageId = null
        downGlobal = null
        notifyListeners()
    }

    private fun applySnap() {
        if (viewportW <= 0) return
        val centre = x + diameter / 2
        x = if (centre < viewportW / 2) {
            BubbleTokens.snapInset
        } else {
            viewportW - diameter - BubbleTokens.snapInset
        }
        clampPosition()
    }

    private fun clampPosition() {
        if (viewportW <= 0 || viewportH <= 0) return
        val maxX = max(0f, viewportW - diameter)
        val maxY = max(
            BubbleTokens.topInset,
            viewportH - diameter - BubbleTokens.bottomInset,
        )
        x = x.coerceIn(0f, maxX)
        y = y.coerceIn(BubbleTokens.topInset, maxY)
    }

    private fun hitTest(global: Pt): String? {
        for ((id, rect) in incomingTargets) {
            if (rect.contains(global)) return id
        }
        return null
    }

    /** Menu placement from prototype: away from the nearest horizontal edge. */
    fun menuOrigin(): Pt {
        val centre = x + diameter / 2
        val onRight = centre >= viewportW / 2
        val left = if (onRight) x - BubbleTokens.menuWidth - 8 else x + diameter + 8
        var top = y
        val maxTop = max(BubbleTokens.menuTopMin, viewportH - BubbleTokens.menuTopMaxOffset)
        top = top.coerceIn(BubbleTokens.menuTopMin, maxTop)
        return Pt(left, top)
    }

    fun hintOrigin(): Pt {
        val centre = x + diameter / 2
        val onRight = centre >= viewportW / 2
        val left = if (onRight) x - BubbleTokens.hintWidth - 8 else x + diameter + 8
        return Pt(left, y)
    }

    private fun notifyListeners() {
        onChanged?.invoke()
    }
}
