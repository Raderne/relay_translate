package com.relay.relay_translate

import com.relay.relay_translate.history.HistoryEventBuffer
import io.flutter.plugin.common.EventChannel

/**
 * `relay/overlay/events` — history rows from native translate (Phase 8+).
 * Bubble menu events land in Phase 7.
 */
class OverlayEventsChannel(messenger: io.flutter.plugin.common.BinaryMessenger) {
    private var sink: EventChannel.EventSink? = null
    private var buffer: HistoryEventBuffer? = null

    private val channel = EventChannel(messenger, "relay/overlay/events").also { ch ->
        ch.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sink = events
                    flushBuffered()
                }

                override fun onCancel(arguments: Any?) {
                    sink = null
                }
            },
        )
    }

    fun attachBuffer(historyBuffer: HistoryEventBuffer) {
        buffer = historyBuffer
    }

    fun emitTranslated(item: HistoryEventBuffer.HistoryItem) {
        val map = item.toEventMap()
        val active = sink
        if (active != null) {
            active.success(mapOf("type" to "translated", "item" to map))
        } else {
            buffer?.enqueue(item)
        }
    }

    fun emitToast(message: String) {
        sink?.success(mapOf("type" to "toast", "message" to message))
    }

    fun flushBuffered() {
        val buf = buffer ?: return
        val pending = buf.drain()
        val active = sink ?: return
        for (item in pending) {
            active.success(mapOf("type" to "translated", "item" to item.toEventMap()))
        }
    }

    fun dispose() {
        sink = null
        channel.setStreamHandler(null)
    }

    companion object {
        var instance: OverlayEventsChannel? = null
            private set

        fun install(messenger: io.flutter.plugin.common.BinaryMessenger): OverlayEventsChannel {
            val ch = OverlayEventsChannel(messenger)
            instance = ch
            return ch
        }
    }
}
