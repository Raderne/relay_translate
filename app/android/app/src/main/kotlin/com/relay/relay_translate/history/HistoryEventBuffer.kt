package com.relay.relay_translate.history

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Buffers history rows when Flutter is not listening; flushed on next [drain].
 */
class HistoryEventBuffer(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enqueue(item: HistoryItem) {
        val arr = JSONArray(prefs.getString(KEY, "[]"))
        arr.put(item.toJson())
        prefs.edit().putString(KEY, arr.toString()).apply()
    }

    fun drain(): List<HistoryItem> {
        val raw = prefs.getString(KEY, "[]") ?: "[]"
        prefs.edit().remove(KEY).apply()
        val arr = JSONArray(raw)
        val out = mutableListOf<HistoryItem>()
        for (i in 0 until arr.length()) {
            out += HistoryItem.fromJson(arr.getJSONObject(i))
        }
        return out
    }

    data class HistoryItem(
        val appPackage: String,
        val appLabel: String,
        val src: String,
        val tr: String,
        val srcLang: String,
        val targetLang: String,
        val ms: Long,
    ) {
        fun toJson(): JSONObject = JSONObject()
            .put("app_package", appPackage)
            .put("app_label", appLabel)
            .put("src", src)
            .put("tr", tr)
            .put("src_lang", srcLang)
            .put("target_lang", targetLang)
            .put("ms", ms)

        fun toEventMap(): Map<String, Any?> = mapOf(
            "app_package" to appPackage,
            "app_label" to appLabel,
            "src" to src,
            "tr" to tr,
            "src_lang" to srcLang,
            "target_lang" to targetLang,
            "ms" to ms,
        )

        companion object {
            fun fromJson(o: JSONObject): HistoryItem = HistoryItem(
                appPackage = o.getString("app_package"),
                appLabel = o.getString("app_label"),
                src = o.getString("src"),
                tr = o.getString("tr"),
                srcLang = o.getString("src_lang"),
                targetLang = o.getString("target_lang"),
                ms = o.getLong("ms"),
            )
        }
    }

    companion object {
        private const val PREFS = "relay_history_buffer"
        private const val KEY = "pending"
    }
}
