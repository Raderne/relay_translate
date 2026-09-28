package com.relay.relay_translate.accessibility

import android.graphics.Rect as AndroidRect
import android.view.accessibility.AccessibilityNodeInfo
import com.relay.relay_translate.extract.ExtractNode
import com.relay.relay_translate.extract.Rect

object AccessibilityNodeMapper {
    fun toExtractNode(node: AccessibilityNodeInfo, depth: Int = 0, maxDepth: Int = 32): ExtractNode {
        val bounds = AndroidRect()
        node.getBoundsInScreen(bounds)
        val children = if (depth >= maxDepth) {
            emptyList()
        } else {
            val list = mutableListOf<ExtractNode>()
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                try {
                    list += toExtractNode(child, depth + 1, maxDepth)
                } finally {
                    child.recycle()
                }
            }
            list
        }
        return ExtractNode(
            text = node.text?.toString(),
            contentDescription = node.contentDescription?.toString(),
            viewId = node.viewIdResourceName,
            className = node.className?.toString(),
            bounds = Rect(bounds.left, bounds.top, bounds.right, bounds.bottom),
            visibleToUser = node.isVisibleToUser,
            editable = node.isEditable,
            children = children,
        )
    }
}
