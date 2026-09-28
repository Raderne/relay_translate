package com.relay.relay_translate.extract

object MessageId {
    fun forMessage(text: String, bounds: Rect): String {
        val payload = "$text\n${bounds.top}"
        return payload.hashCode().toUInt().toString(16)
    }
}
