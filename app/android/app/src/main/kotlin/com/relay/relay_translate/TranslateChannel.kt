package com.relay.relay_translate

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * `relay/translate` MethodChannel — Dart's only way to translate (mirrors `lib/native/translator.dart`).
 *
 * Methods (all arguments are a Map):
 * - `translate {texts: List<String>, target: String, wifiOnly?: Bool}` → `List<{text, source}>`
 * - `ensureModel {lang: String, wifiOnly?: Bool}` → null
 * - `modelStatus {lang: String}` → "ready" | "downloading" | "missing"
 * - `deleteModel {lang: String}` → null
 *
 * Failures arrive as `PlatformException(code = Translator.ErrorCode.*)`.
 */
class TranslateChannel(
    messenger: BinaryMessenger,
    private val translator: Translator,
    private val scope: CoroutineScope,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NAME).also { it.setMethodCallHandler(this) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                result.success(handle(call))
            } catch (e: Translator.TranslateException) {
                result.error(e.code, e.message, null)
            } catch (e: IllegalArgumentException) {
                result.error("bad_args", e.message, null)
            } catch (e: Exception) {
                result.error(Translator.ErrorCode.TRANSLATE_FAILED, e.message, null)
            }
        }
    }

    private suspend fun handle(call: MethodCall): Any? = when (call.method) {
        "translate" -> translator
            .translate(call.list("texts"), call.string("target"), call.wifiOnly())
            .map { mapOf("text" to it.text, "source" to it.source) }
        "ensureModel" -> translator.ensureModel(call.string("lang"), call.wifiOnly()).let { null }
        "modelStatus" -> translator.modelStatus(call.string("lang"))
        "deleteModel" -> translator.deleteModel(call.string("lang")).let { null }
        else -> throw IllegalArgumentException("Unknown method ${call.method}")
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private fun MethodCall.string(key: String): String =
        argument<String>(key) ?: throw IllegalArgumentException("Missing '$key'")

    private fun MethodCall.list(key: String): List<String> =
        argument<List<String>>(key) ?: throw IllegalArgumentException("Missing '$key'")

    private fun MethodCall.wifiOnly(): Boolean = argument<Boolean>("wifiOnly") ?: true

    companion object {
        const val NAME = "relay/translate"
    }
}
