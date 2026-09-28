package com.relay.relay_translate.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.accessibilityservice.AccessibilityService
import com.relay.relay_translate.extract.Rect
import com.relay.relay_translate.extract.toAndroidRect

data class TranslatedOverlayBox(
    val bounds: Rect,
    val translation: String,
    val tag: String,
)

/**
 * Draws translated message boxes over the host app. [AccessibilityService] windows only —
 * removed on scroll / window change.
 */
class TranslationLayer(private val service: AccessibilityService) {
    private val windowManager = service.getSystemService(WindowManager::class.java)
    private var overlayView: TranslationOverlayView? = null
    private var progressView: View? = null

    fun show(boxes: List<TranslatedOverlayBox>) {
        clear()
        if (boxes.isEmpty()) return
        val view = TranslationOverlayView(service).apply { this.boxes = boxes }
        overlayView = view
        windowManager.addView(view, overlayParams())
    }

    fun setProgress(visible: Boolean, fraction: Float = 0f) {
        if (!visible) {
            progressView?.let { windowManager.removeView(it) }
            progressView = null
            return
        }
        if (progressView == null) {
            val bar = ProgressBarView(service)
            progressView = bar
            windowManager.addView(bar, progressParams())
        }
        (progressView as? ProgressBarView)?.fraction = fraction
    }

    fun clear() {
        overlayView?.let { windowManager.removeView(it) }
        overlayView = null
        setProgress(false)
    }

    private fun overlayParams(): WindowManager.LayoutParams =
        WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.TOP or Gravity.START }

    private fun progressParams(): WindowManager.LayoutParams =
        WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            dp(2),
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.TOP }

    private fun dp(v: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), service.resources.displayMetrics).toInt()

    private class TranslationOverlayView(context: Context) : View(context) {
        var boxes: List<TranslatedOverlayBox> = emptyList()

        private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = RelayColors.surface }
        private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = RelayColors.accent
            style = Paint.Style.STROKE
            strokeWidth = dp(1).toFloat()
        }
        private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = RelayColors.text
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        }
        private val tagPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = RelayColors.accent700
            textSize = sp(10)
        }

        override fun onDraw(canvas: Canvas) {
            for (box in boxes) {
                val r = RectF(
                    box.bounds.left.toFloat(),
                    box.bounds.top.toFloat(),
                    box.bounds.right.toFloat(),
                    box.bounds.bottom.toFloat(),
                )
                canvas.drawRect(r, fill)
                canvas.drawRect(r, stroke)
                tagPaint.textSize = sp(10)
                canvas.drawText(box.tag.uppercase(), r.left + dp(4), r.top + dp(12), tagPaint)
                drawFittedText(canvas, box.translation, r)
            }
        }

        private fun drawFittedText(canvas: Canvas, text: String, rect: RectF) {
            var size = sp(14)
            val min = sp(11)
            val maxWidth = rect.width() - dp(8)
            val maxHeight = rect.height() - dp(18)
            textPaint.textSize = size
            while (size > min && textPaint.measureText(text) > maxWidth) {
                size -= 1f
                textPaint.textSize = size
            }
            val lineHeight = textPaint.fontMetrics.let { it.descent - it.ascent }
            var y = rect.top + dp(16) - textPaint.fontMetrics.ascent
            if (lineHeight > maxHeight) {
                textPaint.textSize = min
                y = rect.top + dp(16) - textPaint.fontMetrics.ascent
            }
            canvas.drawText(text, rect.left + dp(4), y, textPaint)
        }

        private fun dp(v: Int): Int =
            TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

        private fun sp(v: Int): Float =
            TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v.toFloat(), resources.displayMetrics)
    }

    private class ProgressBarView(context: Context) : View(context) {
        var fraction: Float = 0f
            set(value) {
                field = value.coerceIn(0f, 1f)
                invalidate()
            }

        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = RelayColors.accent }

        override fun onDraw(canvas: Canvas) {
            val w = width * fraction
            canvas.drawRect(0f, 0f, w, height.toFloat(), paint)
        }
    }
}
