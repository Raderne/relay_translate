package com.relay.relay_translate

import android.content.Intent
import android.os.Bundle
import com.relay.relay_translate.bubble.BubbleService
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
    private var overlayChannel: OverlayChannel? = null
    private var updateChannel: UpdateChannel? = null
    private var betaChannel: BetaChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        captureRoute(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        captureRoute(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val translator = Translator(this).also { translator = it }
        translateChannel = TranslateChannel(messenger, translator, scope)
        permissionsChannel = PermissionsChannel(this, messenger)
        settingsChannel = SettingsChannel(this, messenger)
        overlayEventsChannel = OverlayEventsChannel.install(messenger)
        overlayChannel = OverlayChannel(this, messenger)
        updateChannel = UpdateChannel(this, messenger, scope)
        betaChannel = BetaChannel(this, messenger)
    }

    override fun onResume() {
        super.onResume()
        BubbleService.setHostForeground(true)
    }

    override fun onPause() {
        BubbleService.setHostForeground(false)
        super.onPause()
    }

    override fun onDestroy() {
        translateChannel?.dispose()
        permissionsChannel?.dispose()
        settingsChannel?.dispose()
        overlayEventsChannel?.dispose()
        overlayChannel?.dispose()
        updateChannel?.dispose()
        betaChannel?.dispose()
        scope.cancel()
        translator?.close()
        super.onDestroy()
    }

    private fun captureRoute(intent: Intent?) {
        intent?.getStringExtra(EXTRA_ROUTE)?.let { pendingRoute = it }
        intent?.removeExtra(EXTRA_ROUTE)
    }

    companion object {
        const val EXTRA_ROUTE = "relay_route"
        const val ROUTE_LANGUAGE = "language"
        const val ROUTE_HISTORY = "history"

        /** Set by the overlay menu's Language / History; Dart takes it on start and resume. */
        @Volatile
        private var pendingRoute: String? = null

        fun takePendingRoute(): String? = pendingRoute.also { pendingRoute = null }
    }
}
