import 'package:flutter/services.dart';

import '../data/settings_store.dart';

/// Mirrors a subset of [SettingsStore] into native SharedPreferences for the accessibility service.
class NativeSettingsBridge {
  const NativeSettingsBridge();

  static const channel = MethodChannel('relay/settings');

  Future<void> sync(SettingsStore store) => channel.invokeMethod<void>('sync', {
    'targetLang': store.targetLang,
    'wifiOnly': store.wifiOnlyDownloads,
  });
}
