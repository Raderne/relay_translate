import 'package:flutter/services.dart';

/// Latest GitHub release vs the installed app. From `relay/update` → `UpdateChannel.kt`.
class UpdateInfo {
  const UpdateInfo({required this.current, required this.latest, required this.notes, required this.url});

  final String current;
  final String latest;

  /// Release body = the version's CHANGELOG.md section (markdown).
  final String notes;

  /// APK for this phone's CPU. Null when the release has none.
  final String? url;

  bool get available => url != null && isNewer(latest, current);
}

/// Compares `x.y.z`, ignoring suffixes like `-beta` (flavor) or `+3` (build).
bool isNewer(String latest, String current) {
  List<int> parts(String v) => v.split(RegExp('[-+]')).first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final a = parts(latest), b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

class Updater {
  const Updater();

  static const channel = MethodChannel('relay/update');

  /// Null when offline, rate-limited or there is no release: updates are never worth an error.
  Future<UpdateInfo?> check() async {
    try {
      final m = await channel.invokeMapMethod<String, Object?>('check');
      if (m == null) return null;
      return UpdateInfo(
        current: m['current'] as String? ?? '',
        latest: m['latest'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
        url: m['url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads the APK and returns its local path. [onProgress] gets 0..1.
  Future<String> download(String url, void Function(double) onProgress) async {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'progress') onProgress((call.arguments as num).toDouble());
    });
    try {
      return (await channel.invokeMethod<String>('download', {'url': url}))!;
    } finally {
      channel.setMethodCallHandler(null);
    }
  }

  /// False when Android first needs "Install unknown apps" for Relay (its settings screen opens).
  Future<bool> install(String path) async => await channel.invokeMethod<bool>('install', {'path': path}) ?? false;
}
