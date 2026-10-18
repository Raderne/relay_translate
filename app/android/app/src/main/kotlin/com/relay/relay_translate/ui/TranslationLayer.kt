package com.relay.relay_translate.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.text.TextUtils
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
    /** Phase 9: what the detail sheet shows when the box is tapped. */
    val original: String = "",
    val sourceLang: String = "",
)

/**
 * Draws translated message boxes over the host app. [AccessibilityService] windows only —
 * removed on scroll / window change. Phase 9: one touchable window per box (tap → [onTap], the detail
 * sheet); the rest of the screen still reaches the app.
 */
class TranslationLayer(
    private val service: AccessibilityService,
    private val onTap: (TranslatedOverlayBox) -> Unit = {},
) {
    private val windowManager = service.getSystemService(WindowManager::class.java)
    private val boxViews = mutableListOf<View>()
    private var progressView: View? = null

    fun show(boxes: List<TranslatedOverlayBox>) {
        clear()
        for (box in boxes) {
            val view = TranslationOverlayView(service).apply {
                this.box = box
                contentDescription = box.translation
                setOnClickListener { onTap(box) }
            }
            boxViews += view
            windowManager.addView(view, boxParams(box.bounds))
        }
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
        boxViews.forEach { windowManager.removeView(it) }
        boxViews.clear()
        setProgress(false)
    }

    private fun boxParams(bounds: Rect): WindowManager.LayoutParams =
        WindowManager.LayoutParams(
            bounds.width,
            bounds.height,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = bounds.left
            y = bounds.top
        }

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
        var box: TranslatedOverlayBox? = null

        private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = RelayColors.surface }
        private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = RelayColors.accent
            style = Paint.Style.STROKE
            strokeWidth = dp(1).toFloat()
        }
        private val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = RelayColors.text
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        }

        override fun onDraw(canvas: Canvas) {
            val box = box ?: return
            // The window sits on the message's bounds, so draw in local coordinates.
            val r = RectF(0f, 0f, width.toFloat(), height.toFloat())
            canvas.drawRect(r, fill)
            canvas.drawRect(r, stroke)
            // No "Translated · EN → AR" line (user decision 2026-10-18): the accent outline marks it;
            // the pair is in the detail sheet.
            drawFittedText(canvas, box.translation, r, top = dp(2).toFloat())
        }

        /**
         * Wrapped, direction-aware text (Phase 11): StaticLayout picks RTL from the text itself, so Arabic
         * aligns right; shrinks 14 → 11 sp to fit, then ellipsizes. Tap the box for the full text.
         */
        private fun drawFittedText(canvas: Canvas, text: String, rect: RectF, top: Float) {
            val width = (rect.width() - dp(8)).toInt().coerceAtLeast(1)
            val available = rect.height() - top - dp(2)
            val size = FitText.largestFitting(max = sp(14), min = sp(11)) { s -> layout(text, s, width).height <= available }
            val probe = layout(text, size, width)
            val lineHeight = probe.height.toFloat() / probe.lineCount.coerceAtLeast(1)
            val fitted = layout(text, size, width, maxLines = FitText.linesThatFit(available, lineHeight))
            canvas.save()
            canvas.translate(rect.left + dp(4), rect.top + top)
            fitted.draw(canvas)
            canvas.restore()
        }

        private fun layout(text: String, sizePx: Float, width: Int, maxLines: Int = Int.MAX_VALUE): StaticLayout {
            textPaint.textSize = sizePx
            return StaticLayout.Builder.obtain(text, 0, text.length, textPaint, width)
                .setTextDirection(TextDirectionHeuristics.FIRSTSTRONG_LTR)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .setMaxLines(maxLines)
                .setEllipsize(TextUtils.TruncateAt.END)
                .setIncludePad(false)
                .build()
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
