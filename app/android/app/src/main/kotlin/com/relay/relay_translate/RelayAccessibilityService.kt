package com.relay.relay_translate

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.widget.Toast
import com.relay.relay_translate.accessibility.AccessibilityTranslateCoordinator
import com.relay.relay_translate.accessibility.MessageExtractor
import com.relay.relay_translate.accessibility.OverlayInvalidation
import com.relay.relay_translate.bubble.BubbleService
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
    // Lazy: the service has no Context until onCreate; building it as a field crashed on enable.
    private val historyBuffer by lazy { HistoryEventBuffer(this) }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        val translator = Translator(applicationContext).also { translator = it }
        val layer = TranslationLayer(this) { box -> coordinator?.openDetail(box) }
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
            onToast = { msg ->
                // Overlay toast when the bubble runs; else a system toast (Flutter can't show one over other apps).
                if (!BubbleService.toast(msg)) Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
            },
        )
        OverlayEventsChannel.instance?.attachBuffer(historyBuffer)
        OverlayEventsChannel.instance?.flushBuffered()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val c = coordinator ?: return
        if (OverlayInvalidation.shouldClear(event.eventType, event.packageName?.toString(), packageName, c.shownPackage)) {
            c.invalidateOverlays()
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

        /** Translated boxes are on screen: bubble hold / menu reverts instead of translating. */
        val isShowing: Boolean get() = instance?.coordinator?.isShowing == true

        fun clearFromBubble() {
            instance?.coordinator?.clearOverlays()
        }

        /** Phase 9: `DetailActivity` "Paste into <App>". False when the service is off (caller copies instead). */
        fun pasteFromDetail(appPackage: String, appLabel: String, text: String): Boolean {
            val c = instance?.coordinator ?: return false
            c.paste(appPackage, appLabel, text)
            return true
        }

        /** Called from the overlay bubble on drag-drop. */
        fun translateAtFromBubble(screenX: Int, screenY: Int) {
            instance?.coordinator?.translateAt(screenX, screenY)
                ?: Log.w(TAG, "Accessibility service not running")
        }
    }
}
