import 'package:flutter/services.dart';

/// Phase 10 feedback tools (👎, export, survey) exist only in the `beta` flavor.
bool get isBetaBuild => appFlavor == 'beta';

/// Google Form for testers, linked from Home. The row stays hidden while this is empty.
const kBetaSurveyUrl = '';

/// `relay/beta` → `MainActivity` (share sheet, browser). No packages: plain Android intents.
class BetaBridge {
  const BetaBridge();

  static const channel = MethodChannel('relay/beta');

  /// Writes [json] to a cache file and opens the Android share sheet.
  Future<void> shareJson(String json, {required String fileName}) =>
      channel.invokeMethod<void>('shareJson', {'json': json, 'fileName': fileName});

  Future<void> openUrl(String url) => channel.invokeMethod<void>('openUrl', {'url': url});
}
