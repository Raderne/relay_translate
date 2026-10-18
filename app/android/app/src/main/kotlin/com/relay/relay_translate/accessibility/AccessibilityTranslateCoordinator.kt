package com.relay.relay_translate.accessibility

import android.content.ClipData
import android.content.ClipboardManager
import android.content.pm.PackageManager
import android.util.Log
import android.accessibilityservice.AccessibilityService
import com.relay.relay_translate.DetailActivity
import com.relay.relay_translate.NativeSettings
import com.relay.relay_translate.Translator
import com.relay.relay_translate.extract.DropTargetSelector
import com.relay.relay_translate.extract.ScreenMessage
import com.relay.relay_translate.history.HistoryEventBuffer
import com.relay.relay_translate.paste.Paster
import com.relay.relay_translate.paste.awaitForeground
import com.relay.relay_translate.ui.TranslatedOverlayBox
import com.relay.relay_translate.ui.TranslationLayer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

class AccessibilityTranslateCoordinator(
    private val service: AccessibilityService,
    private val scope: CoroutineScope,
    private val extractor: MessageExtractor,
    private val translator: Translator,
    private val layer: TranslationLayer,
    private val onHistory: (HistoryEventBuffer.HistoryItem) -> Unit,
    private val onToast: (String) -> Unit,
) {
    private var showing = false
    private var shownApp: Pair<String, String>? = null // package, label of the boxes on screen
    val isShowing: Boolean get() = showing
    val shownPackage: String? get() = shownApp?.first

    fun translateAll() {
        scope.launch { readAndTranslate(dropX = null, dropY = null) }
    }

    fun translateAt(screenX: Int, screenY: Int) {
        scope.launch { readAndTranslate(dropX = screenX, dropY = screenY) }
    }

    fun clearOverlays() {
        layer.clear()
        showing = false
    }

    fun invalidateOverlays() {
        if (!showing) return
        clearOverlays()
        onToast("Scrolled · hold again to translate")
    }

    private suspend fun readAndTranslate(dropX: Int?, dropY: Int?) {
        Log.d(TAG_TREE_READ, "on-demand accessibility tree read")
        val root = service.rootInActiveWindow
        val pkg = root?.packageName?.toString()
        val extracted = extractor.extract(root)
        root?.recycle()

        val isDrop = dropX != null && dropY != null
        if (extracted.isEmpty()) {
            // A drop that hits nothing is just the user moving the bubble (prototype: silent).
            if (!isDrop) onToast("Couldn't find messages on this screen")
            return
        }

        val targets = when {
            dropX != null && dropY != null -> {
                val one = DropTargetSelector.select(extracted, dropX, dropY) ?: return
                listOf(one)
            }
            else -> extracted
        }

        val targetLang = NativeSettings.targetLang(service)
        val wifiOnly = NativeSettings.wifiOnly(service)
        layer.setProgress(true, 0.35f)
        val started = System.currentTimeMillis()
        try {
            val results = translator.translate(targets.map { it.text }, targetLang, wifiOnly)
            val appPackage = pkg ?: "unknown"
            val label = appLabel(appPackage)
            val boxes = mutableListOf<TranslatedOverlayBox>()
            targets.zip(results).forEach { (msg, res) ->
                if (res.source == "und") return@forEach
                val elapsed = System.currentTimeMillis() - started
                onHistory(
                    HistoryEventBuffer.HistoryItem(
                        appPackage = appPackage,
                        appLabel = label,
                        src = msg.text,
                        tr = res.text,
                        srcLang = res.source,
                        targetLang = targetLang,
                        ms = elapsed,
                    ),
                )
                val tag = "Translated · ${res.source.uppercase()} → ${targetLang.uppercase()}"
                boxes += TranslatedOverlayBox(msg.bounds, res.text, tag, original = msg.text, sourceLang = res.source)
            }
            layer.setProgress(false)
            if (boxes.isEmpty()) {
                onToast("Couldn't detect language")
                return
            }
            layer.show(boxes)
            shownApp = appPackage to label
            showing = true
        } catch (e: Translator.TranslateException) {
            layer.setProgress(false)
            onToast("Couldn't translate · Retry")
        }
    }

    /**
     * Phase 9: a translated box was tapped. Boxes are cleared (silently) because they would draw over the
     * sheet, then the detail sheet opens over the chat app.
     */
    fun openDetail(box: TranslatedOverlayBox) {
        val (pkg, label) = shownApp ?: return
        clearOverlays()
        service.startActivity(
            DetailActivity.intent(
                service,
                src = box.original,
                tr = box.translation,
                source = box.sourceLang,
                target = NativeSettings.targetLang(service),
                appLabel = label,
                appPackage = pkg,
                wifiOnly = NativeSettings.wifiOnly(service),
            ),
        )
    }

    /** "Paste into <App>": wait for the chat app to be back in front, fill its message box. Never sends. */
    fun paste(appPackage: String, appLabel: String, text: String) {
        scope.launch {
            val back = awaitForeground(appPackage, timeoutMs = 2000, pollMs = 100) {
                service.rootInActiveWindow?.packageName?.toString()
            }
            val root = if (back) service.rootInActiveWindow else null
            if (Paster.paste(root?.let(::AccessibilityPasteNode), text)) {
                onToast("Pasted into $appLabel · tap send")
            } else {
                service.getSystemService(ClipboardManager::class.java)
                    .setPrimaryClip(ClipData.newPlainText("Relay reply", text))
                onToast("Copied · long-press the message box to paste")
            }
        }
    }

    private fun appLabel(packageName: String): String = try {
        val pm = service.packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        packageName
    }

    companion object {
        const val TAG_TREE_READ = "RelayA11yTreeRead"
    }
}
