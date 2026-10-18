package com.relay.relay_translate.paste

import kotlinx.coroutines.delay

/**
 * Polls [currentPackage] until it is [packageName] (the detail sheet has closed and the chat app is in
 * front again) or [timeoutMs] runs out. Returns whether it arrived.
 */
suspend fun awaitForeground(
    packageName: String,
    timeoutMs: Long,
    pollMs: Long,
    currentPackage: () -> String?,
): Boolean {
    var waited = 0L
    while (waited < timeoutMs) {
        if (currentPackage() == packageName) return true
        delay(pollMs)
        waited += pollMs
    }
    return false
}
