package com.relay.relay_translate.accessibility

import android.content.pm.PackageManager
import android.util.Log
import android.accessibilityservice.AccessibilityService
import com.relay.relay_translate.NativeSettings
import com.relay.relay_translate.Translator
import com.relay.relay_translate.extract.DropTargetSelector
import com.relay.relay_translate.extract.ScreenMessage
import com.relay.relay_translate.history.HistoryEventBuffer
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

        if (extracted.isEmpty()) {
            onToast("Couldn't find messages on this screen")
            return
        }

        val targets = when {
            dropX != null && dropY != null -> {
                val one = DropTargetSelector.select(extracted, dropX, dropY)
                if (one == null) {
                    onToast("Drop on a message")
                    return
                }
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
                boxes += TranslatedOverlayBox(msg.bounds, res.text, tag)
            }
            layer.setProgress(false)
            if (boxes.isEmpty()) {
                onToast("Couldn't detect language")
                return
            }
            layer.show(boxes)
            showing = true
        } catch (e: Translator.TranslateException) {
            layer.setProgress(false)
            onToast("Couldn't translate · Retry")
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
