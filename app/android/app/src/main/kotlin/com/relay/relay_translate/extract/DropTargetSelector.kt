package com.relay.relay_translate.extract

/**
 * Picks the message whose bounds contain [x],[y], preferring the smallest area (innermost bubble).
 */
object DropTargetSelector {
    fun select(messages: List<ScreenMessage>, x: Int, y: Int): ScreenMessage? =
        messages
            .filter { it.bounds.contains(x, y) }
            .minByOrNull { it.bounds.area }
}
