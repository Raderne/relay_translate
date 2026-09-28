package com.relay.relay_translate.extract

/**
 * Walks an [ExtractNode] tree and collects message candidates.
 */
object MessageTreeWalker {
    fun collect(
        root: ExtractNode,
        packageName: String,
        skipToolbarHeuristic: Boolean = true,
    ): List<ScreenMessage> {
        val out = mutableListOf<ScreenMessage>()
        walk(root, packageName, skipToolbarHeuristic, out)
        return out
    }

    private fun walk(
        node: ExtractNode,
        packageName: String,
        skipToolbarHeuristic: Boolean,
        out: MutableList<ScreenMessage>,
    ) {
        if (node.editable) return

        val isLeaf = node.children.isEmpty()
        val text = node.displayText()
        if (isLeaf && node.visibleToUser && text != null) {
            if (!MessageNoiseFilter.isNoise(text)) {
                if (AppRules.accepts(packageName, node.viewId)) {
                    if (!skipToolbarHeuristic || !looksLikeToolbar(node)) {
                        val bounds = node.bounds
                        out += ScreenMessage(
                            id = MessageId.forMessage(text, bounds),
                            text = text,
                            bounds = bounds,
                        )
                    }
                }
            }
        }

        for (child in node.children) {
            walk(child, packageName, skipToolbarHeuristic, out)
        }
    }

    /** Top strip with short labels — often the action bar, not chat content. */
    private fun looksLikeToolbar(node: ExtractNode): Boolean {
        val t = node.displayText() ?: return false
        if (t.length > 40) return false
        return node.bounds.top < 200 && node.bounds.height < 80
    }
}
