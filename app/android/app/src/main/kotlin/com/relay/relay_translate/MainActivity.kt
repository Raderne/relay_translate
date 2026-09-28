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
    private var permissionsChannel: PermissionsChannel? = null
    private var settingsChannel: SettingsChannel? = null
    private var overlayEventsChannel: OverlayEventsChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val translator = Translator(this).also { translator = it }
        translateChannel = TranslateChannel(messenger, translator, scope)
        permissionsChannel = PermissionsChannel(this, messenger)
        settingsChannel = SettingsChannel(this, messenger)
        overlayEventsChannel = OverlayEventsChannel.install(messenger)
    }

    override fun onDestroy() {
        translateChannel?.dispose()
        permissionsChannel?.dispose()
        settingsChannel?.dispose()
        overlayEventsChannel?.dispose()
        scope.cancel()
        translator?.close()
        super.onDestroy()
    }
}
