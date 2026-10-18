package com.relay.relay_translate

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import com.relay.relay_translate.bubble.BubbleService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Phase 9: the detail / reply sheet over another app. Transparent Flutter activity on its own engine
 * (Dart entrypoint `detailMain` → `DetailApp`), own task so finishing returns to the chat app.
 * `relay/detail`: `args`, `paste {text}`, `toast {message}`, `close`. Translation still goes through
 * `relay/translate` → [Translator] (CLAUDE.md rule 5).
 */
class DetailActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var translator: Translator? = null
    private var translateChannel: TranslateChannel? = null
    private var detailChannel: MethodChannel? = null

    // ponytail: new engine per open (~0.5–1 s cold); pre-warm one in FlutterEngineCache if that feels slow.
    override fun getDartEntrypointFunctionName(): String = "detailMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val translator = Translator(this).also { translator = it }
        translateChannel = TranslateChannel(messenger, translator, scope)
        detailChannel = MethodChannel(messenger, "relay/detail").also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "args" -> result.success(args())
                    "paste" -> {
                        paste(call.argument<String>("text")!!)
                        result.success(null)
                    }
                    "toast" -> {
                        toast(call.argument<String>("message")!!)
                        result.success(null)
                    }
                    "close" -> {
                        finish()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // Bubble hidden while the sheet is open (same as the Chatter demo).
    override fun onResume() {
        super.onResume()
        BubbleService.setHostForeground(true)
    }

    override fun onPause() {
        BubbleService.setHostForeground(false)
        super.onPause()
    }

    override fun onDestroy() {
        detailChannel?.setMethodCallHandler(null)
        translateChannel?.dispose()
        scope.cancel()
        translator?.close()
        super.onDestroy()
    }

    private fun args(): Map<String, Any> = mapOf(
        "src" to intent.getStringExtra(EXTRA_SRC).orEmpty(),
        "tr" to intent.getStringExtra(EXTRA_TR).orEmpty(),
        "source" to intent.getStringExtra(EXTRA_SOURCE).orEmpty(),
        "target" to intent.getStringExtra(EXTRA_TARGET).orEmpty(),
        "appLabel" to intent.getStringExtra(EXTRA_APP_LABEL).orEmpty(),
        "appPackage" to intent.getStringExtra(EXTRA_APP_PACKAGE).orEmpty(),
        "wifiOnly" to intent.getBooleanExtra(EXTRA_WIFI_ONLY, true),
    )

    /** Finish first so the chat app comes back; the accessibility service then fills its message box. */
    private fun paste(text: String) {
        val pkg = intent.getStringExtra(EXTRA_APP_PACKAGE).orEmpty()
        val label = intent.getStringExtra(EXTRA_APP_LABEL).orEmpty()
        finish()
        if (!RelayAccessibilityService.pasteFromDetail(pkg, label, text)) {
            getSystemService(ClipboardManager::class.java).setPrimaryClip(ClipData.newPlainText("Relay reply", text))
            toast("Copied · long-press the message box to paste")
        }
    }

    private fun toast(message: String) {
        if (!BubbleService.toast(message)) Toast.makeText(applicationContext, message, Toast.LENGTH_LONG).show()
    }

    companion object {
        private const val EXTRA_SRC = "src"
        private const val EXTRA_TR = "tr"
        private const val EXTRA_SOURCE = "source"
        private const val EXTRA_TARGET = "target"
        private const val EXTRA_APP_LABEL = "appLabel"
        private const val EXTRA_APP_PACKAGE = "appPackage"
        private const val EXTRA_WIFI_ONLY = "wifiOnly"

        fun intent(
            context: Context,
            src: String,
            tr: String,
            source: String,
            target: String,
            appLabel: String,
            appPackage: String,
            wifiOnly: Boolean,
        ): Intent = Intent(context, DetailActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .putExtra(EXTRA_SRC, src)
            .putExtra(EXTRA_TR, tr)
            .putExtra(EXTRA_SOURCE, source)
            .putExtra(EXTRA_TARGET, target)
            .putExtra(EXTRA_APP_LABEL, appLabel)
            .putExtra(EXTRA_APP_PACKAGE, appPackage)
            .putExtra(EXTRA_WIFI_ONLY, wifiOnly)
    }
}
