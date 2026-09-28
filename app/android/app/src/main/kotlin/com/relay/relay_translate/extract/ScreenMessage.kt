package com.relay.relay_translate.extract

/**
 * A visible text leaf on another app's screen. [bounds] are in screen coordinates.
 */
data class ScreenMessage(
    val id: String,
    val text: String,
    val bounds: Rect,
)

/** Axis-aligned bounds (screen coords). JVM-testable without Android [android.graphics.Rect]. */
data class Rect(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width: Int get() = right - left
    val height: Int get() = bottom - top
    val area: Int get() = width * height

    fun contains(x: Int, y: Int): Boolean =
        x >= left && x <= right && y >= top && y <= bottom
}

fun Rect.toAndroidRect(): android.graphics.Rect =
    android.graphics.Rect(left, top, right, bottom)
