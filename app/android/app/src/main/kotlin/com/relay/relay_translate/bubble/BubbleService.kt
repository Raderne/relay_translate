package com.relay.relay_translate.bubble

import android.animation.ValueAnimator
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import com.relay.relay_translate.MainActivity
import com.relay.relay_translate.NativeSettings
import com.relay.relay_translate.R
import com.relay.relay_translate.RelayAccessibilityService
import kotlin.math.max

/**
 * Foreground service that owns the system overlay bubble (Phase 7) and its menu / hint / toast windows.
 * Gestures: [BubbleGesture]. Settings: [BubblePrefs], written by `relay/overlay` `apply`.
 * Hidden while Relay itself is in the foreground (the Chatter bubble takes over) and while the screen is off/locked.
 */
class BubbleService : Service() {
    private lateinit var wm: WindowManager
    private lateinit var gesture: BubbleGesture
    private lateinit var bubble: BubbleView
    private lateinit var bubbleParams: WindowManager.LayoutParams
    private val handler = Handler(Looper.getMainLooper())

    private var bubbleAttached = false
    private var menu: View? = null
    private var hint: View? = null
    private var toast: View? = null
    private val hideToast = Runnable { removeToast() }

    private var holdAnim: ValueAnimator? = null
    private var snapAnim: ValueAnimator? = null
    private var dropPx = 0 to 0

    private var screenUsable = true

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            screenUsable = when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> false
                Intent.ACTION_USER_PRESENT -> true
                Intent.ACTION_SCREEN_ON -> !getSystemService(KeyguardManager::class.java).isKeyguardLocked
                else -> screenUsable
            }
            updateVisibility()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WindowManager::class.java)
        startInForeground()
        if (!Settings.canDrawOverlays(this)) {
            stopSelf()
            return
        }
        val prefs = BubblePrefs.read(this)
        gesture = BubbleGesture(
            sizeCode = prefs.size,
            snapEnabled = prefs.snap,
            initialX = prefs.x,
            initialY = prefs.y,
            onTapMenu = ::showMenu,
            onTranslateAll = ::translateAll,
            onTranslateOne = { _ -> translateAt(dropPx.first, dropPx.second) },
            onInteraction = ::dismissHint,
            onPositionPersist = ::persistAndSnap,
            onChanged = ::render,
        )
        bubble = BubbleView(this, prefs.size).apply {
            @Suppress("ClickableViewAccessibility")
            setOnTouchListener { _, e -> onBubbleTouch(e); true }
        }
        bubbleParams = overlayParams(touchable = true)
        refreshViewport()

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, filter)
        }
        instance = this
        updateVisibility()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_HIDE) {
            hide()
            return START_NOT_STICKY
        }
        if (!::gesture.isInitialized) return START_NOT_STICKY // no overlay permission; stopping
        applyPrefs()
        // Restarted with the saved prefs after process death.
        return START_STICKY
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (::gesture.isInitialized) refreshViewport()
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        if (::gesture.isInitialized) {
            unregisterReceiver(screenReceiver)
            holdAnim?.cancel()
            snapAnim?.cancel()
            removeMenu()
            removeHint()
            removeToast()
            if (bubbleAttached) wm.removeView(bubble)
            bubbleAttached = false
        }
        super.onDestroy()
    }

    /** Re-reads [BubblePrefs] after `relay/overlay` `apply`. */
    internal fun applyPrefs() {
        val prefs = BubblePrefs.read(this)
        gesture.sizeCode = prefs.size
        gesture.snapEnabled = prefs.snap
        bubble.sizeCode = prefs.size
        gesture.syncPosition(prefs.x, prefs.y)
        if (prefs.hintSeen) removeHint()
        updateVisibility()
    }

    /** "Hide bubble" (menu) or "Hide" (notification): turns the bubble off until Relay turns it on again. */
    private fun hide() {
        BubblePrefs.setOn(this, false)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    // ---- touch → gesture -------------------------------------------------------------------------

    private fun onBubbleTouch(e: MotionEvent) {
        val density = resources.displayMetrics.density
        val p = Pt(e.rawX / density, e.rawY / density)
        val elapsed = (e.eventTime - e.downTime).toInt()
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                snapAnim?.cancel()
                snapAnim = null
                gesture.pointerDown(p)
                startHold(e.downTime)
            }
            MotionEvent.ACTION_MOVE -> gesture.pointerMove(p)
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                stopHold()
                dropPx = e.rawX.toInt() to e.rawY.toInt()
                gesture.pointerUp(elapsed, p)
            }
        }
    }

    private fun startHold(downTime: Long) {
        holdAnim?.cancel()
        holdAnim = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = BubbleTokens.holdMs.toLong()
            interpolator = LinearInterpolator()
            addUpdateListener { a ->
                // max(): the last frame may land a millisecond before 550.
                val ms = max((SystemClock.uptimeMillis() - downTime).toInt(), (a.animatedFraction * BubbleTokens.holdMs).toInt())
                gesture.tickPressing(ms)
                bubble.ringProgress = gesture.ringProgress(ms)
            }
            start()
        }
    }

    private fun stopHold() {
        holdAnim?.cancel()
        holdAnim = null
        bubble.ringProgress = 0f
    }

    /** `notifyListeners` → redraw the bubble and move its window. */
    private fun render() {
        if (gesture.phase != BubblePhase.PRESSING) bubble.ringProgress = 0f
        bubble.scale = gesture.scale
        bubble.fillAccent = gesture.fillAccent
        if (gesture.phase != BubblePhase.MENU_OPEN) removeMenu()
        if (snapAnim == null) moveBubbleTo(gesture.x, gesture.y)
    }

    private fun moveBubbleTo(xDp: Float, yDp: Float) {
        bubbleParams.x = dpToPx(xDp - BubbleView.PAD_DP)
        bubbleParams.y = dpToPx(yDp - BubbleView.PAD_DP)
        if (bubbleAttached) wm.updateViewLayout(bubble, bubbleParams)
    }

    private fun persistAndSnap(x: Float, y: Float) {
        BubblePrefs.setPosition(this, x, y)
        val fromX = bubbleParams.x
        val toX = dpToPx(x - BubbleView.PAD_DP)
        if (fromX == toX) return
        snapAnim = ValueAnimator.ofInt(fromX, toX).apply {
            duration = BubbleTokens.snapAnimMs.toLong()
            interpolator = DecelerateInterpolator()
            addUpdateListener { a ->
                bubbleParams.x = a.animatedValue as Int
                bubbleParams.y = dpToPx(y - BubbleView.PAD_DP)
                if (bubbleAttached) wm.updateViewLayout(bubble, bubbleParams)
            }
            doOnEnd { snapAnim = null }
            start()
        }
    }

    // ---- translate -------------------------------------------------------------------------------

    private fun translateAll() {
        if (RelayAccessibilityService.instance == null) {
            showToast(MSG_A11Y_OFF)
            return
        }
        if (RelayAccessibilityService.isShowing) {
            RelayAccessibilityService.clearFromBubble()
            showToast("Showing original text")
            return
        }
        RelayAccessibilityService.translateAllFromBubble()
    }

    private fun translateAt(xPx: Int, yPx: Int) {
        if (RelayAccessibilityService.instance == null) {
            showToast(MSG_A11Y_OFF)
            return
        }
        RelayAccessibilityService.translateAtFromBubble(xPx, yPx)
    }

    // ---- menu / hint / toast windows -------------------------------------------------------------

    private fun showMenu() {
        removeMenu()
        val showing = RelayAccessibilityService.isShowing
        val view = menuView(
            this,
            listOf(
                MenuItem(if (showing) "Show original" else "Translate screen") {
                    gesture.dismissMenu()
                    translateAll()
                },
                MenuItem("Language", NativeSettings.targetLang(this).uppercase()) {
                    gesture.dismissMenu()
                    openApp(MainActivity.ROUTE_LANGUAGE)
                },
                MenuItem("History") {
                    gesture.dismissMenu()
                    openApp(MainActivity.ROUTE_HISTORY)
                },
                MenuItem("Hide bubble") {
                    gesture.dismissMenu()
                    hide()
                },
            ),
        )
        @Suppress("ClickableViewAccessibility")
        view.setOnTouchListener { _, e ->
            if (e.actionMasked == MotionEvent.ACTION_OUTSIDE) gesture.dismissMenu()
            false
        }
        val origin = gesture.menuOrigin()
        val params = overlayParams(touchable = true, watchOutside = true).apply {
            x = dpToPx(origin.x - BlueprintFrame.MARK_DP)
            y = dpToPx(origin.y - BlueprintFrame.MARK_DP)
        }
        wm.addView(view, params)
        menu = view
    }

    private fun removeMenu() {
        menu?.let { wm.removeView(it) }
        menu = null
    }

    private fun showHintIfNeeded() {
        if (hint != null || BubblePrefs.read(this).hintSeen) return
        val view = hintView(this).apply { setOnClickListener { dismissHint() } }
        val origin = gesture.hintOrigin()
        val params = overlayParams(touchable = true).apply {
            x = dpToPx(origin.x - BlueprintFrame.MARK_DP)
            y = dpToPx(origin.y - BlueprintFrame.MARK_DP)
        }
        wm.addView(view, params)
        hint = view
    }

    private fun dismissHint() {
        if (!BubblePrefs.read(this).hintSeen) BubblePrefs.setHintSeen(this)
        removeHint()
    }

    private fun removeHint() {
        hint?.let { wm.removeView(it) }
        hint = null
    }

    /** One toast at a time, 3.5 s. Touchable so it never blocks the app below (Android 12 untrusted-touch rule); a tap dismisses it. */
    fun showToast(message: String) {
        removeToast()
        val view = toastView(this, message).apply { setOnClickListener { removeToast() } }
        val params = overlayParams(touchable = true).apply {
            width = viewportPx().first - dpToPx(24f)
            gravity = Gravity.BOTTOM or Gravity.START
            x = dpToPx(12f)
            y = dpToPx(92f)
        }
        wm.addView(view, params)
        toast = view
        handler.postDelayed(hideToast, TOAST_MS)
    }

    private fun removeToast() {
        handler.removeCallbacks(hideToast)
        toast?.let { wm.removeView(it) }
        toast = null
    }

    // ---- visibility, viewport, notification ------------------------------------------------------

    private fun updateVisibility() {
        val visible = !hostForeground && screenUsable
        if (visible && !bubbleAttached) {
            wm.addView(bubble, bubbleParams)
            bubbleAttached = true
            render()
            showHintIfNeeded()
        } else if (!visible && bubbleAttached) {
            holdAnim?.cancel()
            gesture.dismissMenu()
            removeHint()
            wm.removeView(bubble)
            bubbleAttached = false
        }
    }

    private fun refreshViewport() {
        val (w, h) = viewportPx()
        val density = resources.displayMetrics.density
        gesture.setViewport(w / density, h / density)
        render()
    }

    @Suppress("DEPRECATION")
    private fun viewportPx(): Pair<Int, Int> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val b = wm.maximumWindowMetrics.bounds
            return b.width() to b.height()
        }
        val m = DisplayMetrics()
        wm.defaultDisplay.getRealMetrics(m)
        return m.widthPixels to m.heightPixels
    }

    private fun overlayParams(touchable: Boolean, watchOutside: Boolean = false): WindowManager.LayoutParams {
        var flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
        if (!touchable) flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        if (watchOutside) flags = flags or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            flags,
            PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.TOP or Gravity.START }
    }

    private fun startInForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Bubble", NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
            },
        )
        val immutable = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            immutable,
        )
        val hide = PendingIntent.getService(this, 1, Intent(this, BubbleService::class.java).setAction(ACTION_HIDE), immutable)
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_relay_languages)
            .setContentTitle("Relay bubble is on")
            .setContentIntent(open)
            .setOngoing(true)
            .setShowWhen(false)
            .addAction(Notification.Action.Builder(Icon.createWithResource(this, R.drawable.ic_relay_languages), "Hide", hide).build())
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun openApp(route: String) {
        startActivity(
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra(MainActivity.EXTRA_ROUTE, route),
        )
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()

    private fun ValueAnimator.doOnEnd(block: () -> Unit) {
        addListener(object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: android.animation.Animator) = block()
        })
    }

    companion object {
        private const val CHANNEL_ID = "relay_bubble"
        private const val NOTIFICATION_ID = 7
        private const val ACTION_HIDE = "com.relay.relay_translate.bubble.HIDE"
        private const val TOAST_MS = 3500L
        private const val MSG_A11Y_OFF = "Screen text access is off"

        @Volatile
        var instance: BubbleService? = null
            private set

        /** True while a Relay activity is resumed; the bubble steps aside for the in-app one. */
        @Volatile
        private var hostForeground = false

        fun setHostForeground(foreground: Boolean) {
            hostForeground = foreground
            instance?.updateVisibility()
        }

        /** Starts the service, or makes a running one re-read [BubblePrefs]. */
        fun start(context: Context) {
            // A second startForegroundService would need another startForeground; update in place instead.
            instance?.applyPrefs() ?: context.startForegroundService(Intent(context, BubbleService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BubbleService::class.java))
        }

        /** Overlay toast when the bubble is running. False → caller falls back. */
        fun toast(message: String): Boolean {
            val s = instance ?: return false
            s.showToast(message)
            return true
        }
    }
}

/** The service's own copy of the bubble settings (survives the Flutter engine dying). Only native storage besides [NativeSettings]. */
object BubblePrefs {
    private const val PREFS = "relay_bubble"

    data class Values(val on: Boolean, val size: String, val snap: Boolean, val x: Float, val y: Float, val hintSeen: Boolean)

    private fun prefs(context: Context) = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun exists(context: Context) = prefs(context).contains("on")

    fun read(context: Context): Values {
        val p = prefs(context)
        return Values(
            on = p.getBoolean("on", false),
            size = p.getString("size", "M") ?: "M",
            snap = p.getBoolean("snap", true),
            x = p.getFloat("x", 300f),
            y = p.getFloat("y", 600f),
            hintSeen = p.getBoolean("hint_seen", false),
        )
    }

    fun write(context: Context, v: Values) {
        prefs(context).edit()
            .putBoolean("on", v.on)
            .putString("size", v.size)
            .putBoolean("snap", v.snap)
            .putFloat("x", v.x)
            .putFloat("y", v.y)
            .putBoolean("hint_seen", v.hintSeen)
            .apply()
    }

    fun setOn(context: Context, on: Boolean) = prefs(context).edit().putBoolean("on", on).apply()

    fun setPosition(context: Context, x: Float, y: Float) =
        prefs(context).edit().putFloat("x", x).putFloat("y", y).apply()

    fun setHintSeen(context: Context) = prefs(context).edit().putBoolean("hint_seen", true).apply()
}
