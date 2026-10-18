package com.relay.relay_translate

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * `relay/beta` (Phase 10, beta flavor UI only): share the feedback export, open the survey.
 * Plain intents instead of share/url packages (CLAUDE.md rule 6). The export file lives in
 * `cache/exports/`, served by the same FileProvider as updates (`res/xml/update_paths.xml`).
 */
class BetaChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "relay/beta").also { ch ->
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "shareJson" -> {
                    shareJson(call.argument<String>("json")!!, call.argument<String>("fileName")!!)
                    result.success(null)
                }
                "openUrl" -> {
                    activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url")!!)))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareJson(json: String, fileName: String) {
        val dir = File(activity.cacheDir, "exports").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() } // only ever keep the latest export (it holds message text)
        val file = File(dir, File(fileName).name).apply { writeText(json) }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
        val send = Intent(Intent.ACTION_SEND)
            .setType("application/json")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .putExtra(Intent.EXTRA_SUBJECT, "Relay beta feedback")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        activity.startActivity(Intent.createChooser(send, "Send beta feedback"))
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
