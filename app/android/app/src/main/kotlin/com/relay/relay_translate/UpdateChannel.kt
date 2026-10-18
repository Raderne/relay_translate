package com.relay.relay_translate

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * `relay/update` — self-update from GitHub Releases (APKs published by `.github/workflows/release.yml`).
 * No message text is involved: only the public releases API and the APK download.
 *
 * - `check` → `{current, latest, notes, url}`; `url` is the APK for this phone's ABI, null if none
 * - `download {url}` → local path; calls Dart `progress(0..1)` while it runs
 * - `install {path}` → true when the system installer opened; false when "Install unknown apps" is
 *   off (its settings screen is opened instead)
 */
class UpdateChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
    private val scope: CoroutineScope,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME).also { it.setMethodCallHandler(this) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                result.success(handle(call))
            } catch (e: Exception) {
                result.error("update_failed", e.message, null)
            }
        }
    }

    private suspend fun handle(call: MethodCall): Any? = when (call.method) {
        "check" -> check()
        "download" -> download(call.string("url"))
        "install" -> install(File(call.string("path")))
        else -> throw IllegalArgumentException("Unknown method ${call.method}")
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private suspend fun check(): Map<String, Any?> = withContext(Dispatchers.IO) {
        val conn = open(LATEST_RELEASE).apply { setRequestProperty("Accept", "application/vnd.github+json") }
        val release = try {
            JSONObject(conn.inputStream.bufferedReader().use { it.readText() })
        } finally {
            conn.disconnect()
        }
        val assets = release.getJSONArray("assets").let { a -> (0 until a.length()).map(a::getJSONObject) }
        // release.yml names APKs `relay-translate-<version>-<abi>.apk`; SUPPORTED_ABIS is best-first.
        val apk = Build.SUPPORTED_ABIS.firstNotNullOfOrNull { abi ->
            assets.firstOrNull { it.getString("name").endsWith("-$abi.apk") }
        }
        mapOf(
            "current" to activity.packageManager.getPackageInfo(activity.packageName, 0).versionName,
            "latest" to release.getString("tag_name").removePrefix("v"),
            "notes" to release.optString("body"),
            "url" to apk?.getString("browser_download_url"),
        )
    }

    private suspend fun download(url: String): String = withContext(Dispatchers.IO) {
        val file = File(activity.cacheDir, "updates/update.apk").apply { parentFile!!.mkdirs() }
        val conn = open(url)
        try {
            val total = conn.contentLengthLong
            var done = 0L
            var lastPct = -1
            conn.inputStream.use { input ->
                file.outputStream().use { out ->
                    val buf = ByteArray(64 * 1024)
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        out.write(buf, 0, n)
                        done += n
                        val pct = if (total > 0) (done * 100 / total).toInt() else continue
                        if (pct != lastPct) {
                            lastPct = pct
                            activity.runOnUiThread { channel.invokeMethod("progress", pct / 100.0) }
                        }
                    }
                }
            }
        } finally {
            conn.disconnect()
        }
        file.absolutePath
    }

    private fun install(file: File): Boolean {
        val pm = activity.packageManager
        if (!pm.canRequestPackageInstalls()) {
            activity.startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")),
            )
            return false
        }
        // Android checks the signature; this stops a wrong-flavor APK installing as a second app.
        val pkg = pm.getPackageArchiveInfo(file.path, 0)?.packageName
        require(pkg == activity.packageName) { "Update is for $pkg, not ${activity.packageName}" }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
        activity.startActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),
        )
        return true
    }

    private fun open(url: String) = (URL(url).openConnection() as HttpURLConnection).apply {
        connectTimeout = 15_000
        readTimeout = 30_000
    }

    private fun MethodCall.string(key: String): String =
        argument<String>(key) ?: throw IllegalArgumentException("Missing '$key'")

    private companion object {
        const val NAME = "relay/update"
        const val LATEST_RELEASE = "https://api.github.com/repos/Raderne/relay_translate/releases/latest"
    }
}
