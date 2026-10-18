package com.relay.relay_translate.bubble

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.relay.relay_translate.R
import com.relay.relay_translate.ui.RelayColors
import com.relay.relay_translate.ui.RelayFonts

/*
 * Native twins of the Chatter widgets in `app/lib/screens/chatter_screen.dart`
 * (_BubbleView, _RingPainter, _BubbleMenu, _BubbleHint, _ChatterToast) and `Blueprint` in theme/widgets.dart.
 */

internal fun Context.dp(v: Float): Float =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, resources.displayMetrics)

internal fun Context.sp(v: Float): Float =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, resources.displayMetrics)

/**
 * Circle + hold ring. The window is the circle plus [PAD_DP] on each side, which holds the ring,
 * the 1.08 drag scale and a small shadow. Touches in that margin still go to the bubble.
 */
@SuppressLint("ViewConstructor")
class BubbleView(context: Context, sizeCode: String) : View(context) {
    var sizeCode: String = sizeCode
        set(value) {
            field = value
            requestLayout()
        }
    var scale = 1f
        set(value) {
            if (field != value) {
                field = value
                invalidate()
            }
        }
    var ringProgress = 0f
        set(value) {
            if (field != value) {
                field = value
                invalidate()
            }
        }
    var fillAccent = false
        set(value) {
            if (field != value) {
                field = value
                invalidate()
            }
        }

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val border = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = RelayColors.bg
        strokeWidth = context.dp(2f)
    }
    private val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = RelayColors.accent700
        strokeWidth = context.dp(BubbleTokens.ringStroke)
    }
    private val icon = context.getDrawable(R.drawable.ic_relay_languages)!!.mutate().apply { setTint(RelayColors.bg) }
    private val arc = RectF()

    init {
        // Prototype uses RelayShadows.lg (32 blur); that needs a window far bigger than the bubble, which
        // would swallow taps meant for the app below. A small shadow keeps the window tight.
        fill.setShadowLayer(context.dp(4f), 0f, context.dp(2f), RelayColors.shadowMd)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) setLayerType(LAYER_TYPE_SOFTWARE, null)
        contentDescription = "Relay bubble"
    }

    val diameterDp: Float get() = bubbleDiameter(sizeCode).toFloat()

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val side = context.dp(diameterDp + 2 * PAD_DP).toInt()
        setMeasuredDimension(side, side)
    }

    override fun onDraw(canvas: Canvas) {
        val c = width / 2f
        val r = context.dp(diameterDp) / 2
        canvas.save()
        canvas.scale(scale, scale, c, c)
        if (ringProgress > 0f) {
            val rr = r + context.dp(BubbleTokens.ringPad)
            arc.set(c - rr, c - rr, c + rr, c + rr)
            canvas.drawArc(arc, -90f, 360f * ringProgress, false, ring)
        }
        fill.color = if (fillAccent) RelayColors.accent700 else RelayColors.accent
        canvas.drawCircle(c, c, r, fill)
        canvas.drawCircle(c, c, r - border.strokeWidth / 2, border)
        val half = (r * 2 * BubbleTokens.iconFraction / 2).toInt()
        icon.setBounds((c - half).toInt(), (c - half).toInt(), (c + half).toInt(), (c + half).toInt())
        icon.draw(canvas)
        canvas.restore()
    }

    companion object {
        const val PAD_DP = 10f
    }
}

/** `Blueprint`: 1 dp divider border, bg fill, 11 dp crosshair marks centred on each corner. */
class BlueprintFrame(context: Context) : FrameLayout(context) {
    private val mark = context.dp(MARK_DP)
    private val borderPaint = Paint().apply {
        style = Paint.Style.STROKE
        color = RelayColors.divider
        strokeWidth = context.dp(1f)
    }
    private val fillPaint = Paint().apply { color = RelayColors.bg }
    private val markPaint = Paint().apply {
        color = RelayColors.mark
        strokeWidth = context.dp(1f)
        strokeCap = Paint.Cap.SQUARE
    }

    init {
        setWillNotDraw(false)
        val m = mark.toInt()
        setPadding(m, m, m, m)
    }

    override fun onDraw(canvas: Canvas) {
        val l = mark
        val t = mark
        val r = width - mark
        val b = height - mark
        canvas.drawRect(l, t, r, b, fillPaint)
        val half = borderPaint.strokeWidth / 2
        canvas.drawRect(l + half, t + half, r - half, b - half, borderPaint)
        val arm = context.dp(5.5f)
        for ((x, y) in listOf(l to t, r to t, l to b, r to b)) {
            canvas.drawLine(x, y - arm, x, y + arm, markPaint)
            canvas.drawLine(x - arm, y, x + arm, y, markPaint)
        }
    }

    companion object {
        /** Space outside the box for the corner marks; window origin = box origin − this. */
        const val MARK_DP = 6f
    }
}

private class FontSpan(private val typeface: Typeface, private val sizePx: Float) : MetricAffectingSpan() {
    override fun updateDrawState(tp: TextPaint) = apply(tp)
    override fun updateMeasureState(tp: TextPaint) = apply(tp)
    private fun apply(tp: TextPaint) {
        tp.typeface = typeface
        tp.textSize = sizePx
    }
}

private fun TextView.style(typeface: Typeface, sizeSp: Float, color: Int, lineHeight: Float? = null) {
    this.typeface = typeface
    setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
    setTextColor(color)
    includeFontPadding = false
    if (lineHeight != null) setLineSpacing(0f, lineHeight)
}

data class MenuItem(val label: String, val trailing: String? = null, val onTap: () -> Unit)

/** `_BubbleMenu`: four rows, 190 dp wide. */
fun menuView(context: Context, items: List<MenuItem>): BlueprintFrame {
    val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
    items.forEachIndexed { i, item ->
        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val h = context.dp(12f).toInt()
            val v = context.dp(11f).toInt()
            setPadding(h, v, h, v)
            setOnClickListener { item.onTap() }
        }
        row.addView(
            TextView(context).apply {
                text = item.label
                style(RelayFonts.body(context), 14f, RelayColors.text, 1.35f)
            },
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f),
        )
        item.trailing?.let { t ->
            row.addView(
                TextView(context).apply {
                    text = t
                    style(RelayFonts.headingSemiBold(context), 13f, RelayColors.accent700)
                },
            )
        }
        column.addView(row)
        if (i < items.lastIndex) {
            column.addView(
                View(context).apply { setBackgroundColor(RelayColors.divider) },
                LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, context.dp(1f).toInt()),
            )
        }
    }
    return BlueprintFrame(context).apply {
        addView(column, FrameLayout.LayoutParams(context.dp(BubbleTokens.menuWidth).toInt(), FrameLayout.LayoutParams.WRAP_CONTENT))
    }
}

/** `_BubbleHint`: first-run hint, 200 dp wide. */
fun hintView(context: Context): BlueprintFrame {
    val bold = RelayFonts.headingSemiBold(context)
    val boldSize = context.sp(15f)
    val text = SpannableStringBuilder().apply {
        fun strong(s: String) {
            val start = length
            append(s)
            setSpan(FontSpan(bold, boldSize), start, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(android.text.style.ForegroundColorSpan(RelayColors.text), start, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        strong("Hold")
        append(" to translate this screen. ")
        strong("Drag")
        append(" onto a message to translate one.")
    }
    val label = TextView(context).apply {
        this.text = text
        style(RelayFonts.body(context), 13f, RelayColors.neutral700, 1.4f)
        val h = context.dp(12f).toInt()
        val v = context.dp(10f).toInt()
        setPadding(h, v, h, v)
    }
    return BlueprintFrame(context).apply {
        addView(label, FrameLayout.LayoutParams(context.dp(BubbleTokens.hintWidth).toInt(), FrameLayout.LayoutParams.WRAP_CONTENT))
    }
}

/** `_ChatterToast` without the action button (overlay toasts are text only). */
fun toastView(context: Context, message: String): TextView = TextView(context).apply {
    text = message
    style(RelayFonts.body(context), 13.5f, RelayColors.neutral100, 1.3f)
    setBackgroundColor(RelayColors.neutral900)
    setPadding(context.dp(14f).toInt(), context.dp(10f).toInt(), context.dp(12f).toInt(), context.dp(10f).toInt())
}
