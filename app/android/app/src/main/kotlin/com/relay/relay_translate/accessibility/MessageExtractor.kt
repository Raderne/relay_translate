package com.relay.relay_translate.accessibility

import android.view.accessibility.AccessibilityNodeInfo
import com.relay.relay_translate.extract.MessageTreeWalker
import com.relay.relay_translate.extract.ScreenMessage

/**
 * Reads the active window tree on demand (hold / drop only — never from [onAccessibilityEvent]).
 */
class MessageExtractor(
    private val ownPackage: String,
    private val skipPackages: Set<String> = defaultSkipPackages(ownPackage),
) {
    fun extract(root: AccessibilityNodeInfo?): List<ScreenMessage> {
        if (root == null) return emptyList()
        val pkg = root.packageName?.toString() ?: return emptyList()
        if (skipPackages.contains(pkg)) return emptyList()
        val tree = AccessibilityNodeMapper.toExtractNode(root)
        return MessageTreeWalker.collect(tree, pkg)
    }

    companion object {
        fun defaultSkipPackages(ownPackage: String): Set<String> = setOf(
            ownPackage,
            "com.android.systemui",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
        )
    }
}
