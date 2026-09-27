package com.relay.relay_translate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var translator: Translator? = null
    private var translateChannel: TranslateChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val translator = Translator(this).also { translator = it }
        translateChannel = TranslateChannel(flutterEngine.dartExecutor.binaryMessenger, translator, scope)
    }

    override fun onDestroy() {
        translateChannel?.dispose()
        scope.cancel()
        translator?.close()
        super.onDestroy()
    }
}
