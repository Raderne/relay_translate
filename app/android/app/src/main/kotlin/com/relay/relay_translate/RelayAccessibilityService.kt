package com.relay.relay_translate

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import com.relay.relay_translate.accessibility.AccessibilityTranslateCoordinator
import com.relay.relay_translate.accessibility.MessageExtractor
import com.relay.relay_translate.history.HistoryEventBuffer
import com.relay.relay_translate.ui.TranslationLayer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Reads other apps' message text **only** when the overlay bubble requests hold/drop (Phase 7 →
 * [translateAllFromBubble] / [translateAtFromBubble]). Window events only invalidate drawn boxes.
 *
 * `isAccessibilityTool` stays false — see the Play accessibility gotcha.
 */
class RelayAccessibilityService : AccessibilityService() {
    private val job = SupervisorJob()
    private val scope = CoroutineScope(job + Dispatchers.Main.immediate)
    private var translator: Translator? = null
    private var coordinator: AccessibilityTranslateCoordinator? = null
    private val historyBuffer = HistoryEventBuffer(this)

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        val translator = Translator(applicationContext).also { translator = it }
        val layer = TranslationLayer(this)
        coordinator = AccessibilityTranslateCoordinator(
            service = this,
            scope = scope,
            extractor = MessageExtractor(packageName),
            translator = translator,
            layer = layer,
            onHistory = { item ->
                OverlayEventsChannel.instance?.emitTranslated(item)
                    ?: historyBuffer.enqueue(item)
            },
            onToast = { msg -> OverlayEventsChannel.instance?.emitToast(msg) },
        )
        OverlayEventsChannel.instance?.attachBuffer(historyBuffer)
        OverlayEventsChannel.instance?.flushBuffered()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_VIEW_SCROLLED,
            -> coordinator?.invalidateOverlays()
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        coordinator?.clearOverlays()
        scope.cancel()
        translator?.close()
        if (instance === this) instance = null
        super.onDestroy()
    }

    companion object {
        private const val TAG = "RelayAccessibility"

        @Volatile
        var instance: RelayAccessibilityService? = null

        /** Called from the system overlay bubble (Phase 7) on long-press complete. */
        fun translateAllFromBubble() {
            instance?.coordinator?.translateAll()
                ?: Log.w(TAG, "Accessibility service not running")
        }

        /** Called from the overlay bubble on drag-drop. */
        fun translateAtFromBubble(screenX: Int, screenY: Int) {
            instance?.coordinator?.translateAt(screenX, screenY)
                ?: Log.w(TAG, "Accessibility service not running")
        }
    }
}
