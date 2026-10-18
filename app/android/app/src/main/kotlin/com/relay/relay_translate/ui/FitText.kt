package com.relay.relay_translate.ui

import kotlin.math.floor
import kotlin.math.max

/** Text fitting for translated boxes (pure; `FitTextTest`). Sizes in px, step 1. */
object FitText {
    /** Largest size in [min, max] for which [fits] holds; [min] when none does (then ellipsize). */
    fun largestFitting(max: Float, min: Float, fits: (Float) -> Boolean): Float {
        var size = max
        while (size > min && !fits(size)) size -= 1f
        return max(size, min)
    }

    fun linesThatFit(availableHeight: Float, lineHeight: Float): Int =
        max(1, floor(availableHeight / lineHeight).toInt())
}
