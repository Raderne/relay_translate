import 'package:flutter/services.dart';

/// One translated text plus the language it was detected as (BCP-47, or
/// `und` when ML Kit could not tell — then [text] is the untouched original).
class Translation {
  const Translation({required this.text, required this.source});

  final String text;
  final String source;

  bool get undetected => source == 'und';
}

enum ModelStatus { ready, downloading, missing }

/// Typed failure from the native side. [code] values match
/// `Translator.ErrorCode` in `Translator.kt`.
class TranslateException implements Exception {
  const TranslateException(this.code, this.message);

  final String code;
  final String message;

  static const unsupportedLanguage = 'unsupported_language';
  static const noNetwork = 'no_network';
  static const wifiRequired = 'wifi_required';
  static const modelDownloadFailed = 'model_download_failed';
  static const translateFailed = 'translate_failed';

  @override
  String toString() => 'TranslateException($code): $message';
}

/// Dart face of the one translation path. Everything in the app that needs a
/// translation goes through here → `relay/translate` → `Translator.kt`
/// (on-device ML Kit). Dart never talks to a translation engine directly.
class Translator {
  const Translator();

  static const channel = MethodChannel('relay/translate');

  /// Translates [texts] into [target]. Output order == input order.
  Future<List<Translation>> translate(
    List<String> texts,
    String target, {
    bool wifiOnly = true,
  }) async {
    final raw = await _invoke<List<Object?>>('translate', {
      'texts': texts,
      'target': target,
      'wifiOnly': wifiOnly,
    });
    return raw.map((e) {
      final m = e! as Map<Object?, Object?>;
      return Translation(text: m['text']! as String, source: m['source']! as String);
    }).toList(growable: false);
  }

  /// Downloads the model for [lang] if it is not on the device yet.
  Future<void> ensureModel(String lang, {bool wifiOnly = true}) =>
      _invoke<void>('ensureModel', {'lang': lang, 'wifiOnly': wifiOnly});

  Future<ModelStatus> modelStatus(String lang) async {
    final s = await _invoke<String>('modelStatus', {'lang': lang});
    return ModelStatus.values.byName(s);
  }

  Future<void> deleteModel(String lang) => _invoke<void>('deleteModel', {'lang': lang});

  Future<T> _invoke<T>(String method, Map<String, Object?> args) async {
    try {
      return (await channel.invokeMethod<T>(method, args)) as T;
    } on PlatformException catch (e) {
      throw TranslateException(e.code, e.message ?? e.code);
    }
  }
}
