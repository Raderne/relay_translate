import 'dart:async';

import 'package:flutter/services.dart';

import '../data/history_repository.dart';

/// Native overlay / accessibility events (`relay/overlay/events`).
class OverlayEvents {
  const OverlayEvents();

  static const channel = EventChannel('relay/overlay/events');

  static StreamSubscription<dynamic>? listen(HistoryRepository history) {
    return channel.receiveBroadcastStream().listen((event) async {
      if (event is! Map) return;
      final type = event['type'];
      if (type != 'translated') return;
      final item = event['item'];
      if (item is! Map) return;
      await history.logTranslation(
        src: item['src']! as String,
        tr: item['tr']! as String,
        srcLang: item['src_lang']! as String,
        targetLang: item['target_lang']! as String,
        ms: (item['ms'] as num).toInt(),
        appPackage: item['app_package']! as String,
        appLabel: item['app_label']! as String,
      );
    });
  }
}
