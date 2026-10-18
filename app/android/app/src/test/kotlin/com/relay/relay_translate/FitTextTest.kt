package com.relay.relay_translate

import com.relay.relay_translate.ui.FitText
import org.junit.Assert.assertEquals
import org.junit.Test

/** Phase 11: translated boxes shrink the text to fit, down to a floor, then ellipsize. */
class FitTextTest {
    @Test
    fun keepsTheLargestSizeThatFits() {
        assertEquals(14f, FitText.largestFitting(max = 14f, min = 11f) { true })
    }

    @Test
    fun stepsDownUntilItFits() {
        assertEquals(12f, FitText.largestFitting(max = 14f, min = 11f) { size -> size <= 12f })
    }

    @Test
    fun neverGoesBelowTheFloor() {
        assertEquals(11f, FitText.largestFitting(max = 14f, min = 11f) { false })
    }

    @Test
    fun linesThatFitAtLeastOne() {
        assertEquals(3, FitText.linesThatFit(availableHeight = 50f, lineHeight = 16f))
        assertEquals(1, FitText.linesThatFit(availableHeight = 5f, lineHeight = 16f))
    }
}
