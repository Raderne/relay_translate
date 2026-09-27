package com.relay.relay_translate

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import com.google.android.gms.tasks.Task
import com.google.mlkit.common.MlKitException
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.TranslatorOptions
import java.io.Closeable
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import com.google.mlkit.nl.translate.Translator as MlTranslator

/**
 * The ONE translation path (CLAUDE.md rule 5): Google ML Kit, fully on-device.
 * Used by Flutter over the `relay/translate` channel ([TranslateChannel]) and, from Phase 8, directly
 * by the accessibility service. Message text never leaves the device.
 *
 * Language codes are BCP-47 tags as ML Kit uses them ("en", "fr", "pt", …).
 */
class Translator(context: Context) : Closeable {

    data class Result(val text: String, val source: String)

    /** Typed failure; [code] is what the UI maps to a toast. */
    class TranslateException(val code: String, message: String, cause: Throwable? = null) :
        Exception(message, cause)

    object ErrorCode {
        const val UNSUPPORTED_LANGUAGE = "unsupported_language"
        /** No connectivity at all. */
        const val NO_NETWORK = "no_network"
        /** `wifi_only_downloads` is on and the device is on mobile data. */
        const val WIFI_REQUIRED = "wifi_required"
        const val MODEL_DOWNLOAD_FAILED = "model_download_failed"
        const val TRANSLATE_FAILED = "translate_failed"
    }

    private val connectivity = context.applicationContext.getSystemService(ConnectivityManager::class.java)

    object ModelStatus {
        const val READY = "ready"
        const val DOWNLOADING = "downloading"
        const val MISSING = "missing"
    }

    private val languageId = LanguageIdentification.getClient()
    private val models = RemoteModelManager.getInstance()
    private val clients = ConcurrentHashMap<Pair<String, String>, MlTranslator>()
    private val downloading = ConcurrentHashMap.newKeySet<String>()

    /**
     * Detects each text's language, skips the ones already in [target], makes sure the needed models
     * are on the device, then translates the batch concurrently. Output order == input order.
     * Undetectable texts come back unchanged with `source = "und"`.
     */
    suspend fun translate(texts: List<String>, target: String, wifiOnly: Boolean = true): List<Result> {
        val targetCode = translateCode(target)
        val sources = LanguageDetection.resolveSources(texts) { text ->
            val best = languageId.identifyPossibleLanguages(text).await().firstOrNull()
            Detected(best?.languageTag ?: LanguageDetection.UND, best?.confidence ?: 0f)
        }

        val needed = sources.filter { it != LanguageDetection.UND && it != targetCode }.toSet()
        // Language-id can return tags ML Kit Translate can't handle (e.g. "zh-Latn"): fail loudly.
        val sourceCodes = needed.associateWith { translateCode(it) }
        (sourceCodes.values + targetCode).toSet().forEach { ensureModel(it, wifiOnly) }

        return coroutineScope {
            texts.zip(sources) { text, source ->
                async {
                    when {
                        source == LanguageDetection.UND || source == targetCode -> Result(text, source)
                        else -> Result(client(sourceCodes.getValue(source), targetCode).translateText(text), source)
                    }
                }
            }.awaitAll()
        }
    }

    /** Downloads the model for [lang] if missing. No-op when it is already on the device. */
    suspend fun ensureModel(lang: String, wifiOnly: Boolean = true) {
        val code = translateCode(lang)
        val model = TranslateRemoteModel.Builder(code).build()
        if (models.isModelDownloaded(model).await()) return
        // ML Kit queues downloads in DownloadManager and waits for connectivity *forever* (verified on
        // the emulator in airplane mode), so fail fast ourselves instead of showing an endless spinner.
        requireNetwork(wifiOnly)
        val conditions = DownloadConditions.Builder().apply { if (wifiOnly) requireWifi() }.build()
        downloading += code
        try {
            models.download(model, conditions).await()
        } catch (e: MlKitException) {
            val errorCode = if (e.errorCode == MlKitException.NETWORK_ISSUE) ErrorCode.NO_NETWORK
            else ErrorCode.MODEL_DOWNLOAD_FAILED
            throw TranslateException(errorCode, "Could not download the $code model: ${e.message}", e)
        } finally {
            downloading -= code
        }
    }

    suspend fun modelStatus(lang: String): String {
        val code = translateCode(lang)
        return when {
            code in downloading -> ModelStatus.DOWNLOADING
            models.isModelDownloaded(TranslateRemoteModel.Builder(code).build()).await() -> ModelStatus.READY
            else -> ModelStatus.MISSING
        }
    }

    suspend fun deleteModel(lang: String) {
        val code = translateCode(lang)
        clients.keys.filter { it.first == code || it.second == code }.forEach { clients.remove(it)?.close() }
        models.deleteDownloadedModel(TranslateRemoteModel.Builder(code).build()).await()
    }

    override fun close() {
        clients.values.forEach { it.close() }
        clients.clear()
        languageId.close()
    }

    private fun requireNetwork(wifiOnly: Boolean) {
        val caps = connectivity.activeNetwork?.let(connectivity::getNetworkCapabilities)
        if (caps == null || !caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
            throw TranslateException(ErrorCode.NO_NETWORK, "No internet connection to download the model")
        }
        val unmetered = caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
        if (wifiOnly && !unmetered) {
            throw TranslateException(ErrorCode.WIFI_REQUIRED, "Model downloads are set to Wi-Fi only")
        }
    }

    private fun client(source: String, target: String): MlTranslator =
        clients.getOrPut(source to target) {
            Translation.getClient(
                TranslatorOptions.Builder().setSourceLanguage(source).setTargetLanguage(target).build(),
            )
        }

    private suspend fun MlTranslator.translateText(text: String): String = try {
        translate(text).await()
    } catch (e: MlKitException) {
        throw TranslateException(ErrorCode.TRANSLATE_FAILED, e.message ?: "Translation failed", e)
    }

    private fun translateCode(tag: String): String =
        TranslateLanguage.fromLanguageTag(tag)
            ?: throw TranslateException(ErrorCode.UNSUPPORTED_LANGUAGE, "ML Kit can't translate \"$tag\"")
}

/** Minimal Task → coroutine bridge, so we don't pull in kotlinx-coroutines-play-services. */
internal suspend fun <T> Task<T>.await(): T = suspendCancellableCoroutine { cont ->
    addOnSuccessListener { cont.resume(it) }
    addOnFailureListener { cont.resumeWithException(it) }
    addOnCanceledListener { cont.cancel() }
}
