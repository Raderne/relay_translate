import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

/// `settings` row keys. Values are strings in SQLite.
abstract final class SettingsKeys {
  static const targetLang = 'target_lang';
  static const bubbleOn = 'bubble_on';
  static const snap = 'snap';
  static const size = 'size';
  static const bubbleX = 'bubble_x';
  static const bubbleY = 'bubble_y';
  static const onboarded = 'onboarded';
  static const hintSeen = 'hint_seen';
  static const wifiOnlyDownloads = 'wifi_only_downloads';

  static const all = [
    targetLang,
    bubbleOn,
    snap,
    size,
    bubbleX,
    bubbleY,
    onboarded,
    hintSeen,
    wifiOnlyDownloads,
  ];
}

const _defaults = <String, String>{
  SettingsKeys.targetLang: 'fr',
  SettingsKeys.bubbleOn: '1',
  SettingsKeys.snap: '1',
  SettingsKeys.size: 'M',
  SettingsKeys.bubbleX: '300',
  SettingsKeys.bubbleY: '600',
  SettingsKeys.onboarded: '0',
  SettingsKeys.hintSeen: '0',
  SettingsKeys.wifiOnlyDownloads: '1',
};

int bubbleDiameter(String size) => switch (size) {
  'S' => 44,
  'M' => 52,
  'L' => 60,
  _ => 52,
};

double clampBubbleX(double x, String size, double screenWidth) {
  final max = screenWidth - bubbleDiameter(size);
  if (max <= 0) return 0;
  return x.clamp(0, max);
}

/// Loads all settings once, writes through on change. No `shared_preferences`.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._db, [Map<String, String>? seed]) : _values = {...?seed};

  final Database? _db;
  final Map<String, String> _values;

  static Future<SettingsStore> open({Database? database}) async {
    final db = database ?? await openRelayDatabase();
    final store = SettingsStore(db);
    await store._load();
    return store;
  }

  /// Widget tests: no sqflite I/O (ffi deadlocks outside [WidgetTester.runAsync]).
  static SettingsStore inMemory() {
    return SettingsStore(null, Map<String, String>.from(_defaults));
  }

  String get targetLang => _values[SettingsKeys.targetLang] ?? _defaults[SettingsKeys.targetLang]!;
  bool get bubbleOn => _bool(SettingsKeys.bubbleOn);
  bool get snap => _bool(SettingsKeys.snap);
  String get size => _values[SettingsKeys.size] ?? 'M';
  double get bubbleX => _double(SettingsKeys.bubbleX);
  double get bubbleY => _double(SettingsKeys.bubbleY);
  bool get onboarded => _bool(SettingsKeys.onboarded);
  bool get hintSeen => _bool(SettingsKeys.hintSeen);
  bool get wifiOnlyDownloads => _bool(SettingsKeys.wifiOnlyDownloads);

  Future<void> setTargetLang(String code) => _set(SettingsKeys.targetLang, code);

  Future<void> setBubbleOn(bool on) => _set(SettingsKeys.bubbleOn, _fromBool(on));

  Future<void> setSnap(bool on) => _set(SettingsKeys.snap, _fromBool(on));

  Future<void> setSize(String size, {required double screenWidth}) async {
    final clamped = clampBubbleX(bubbleX, size, screenWidth);
    if (_db == null) {
      _values[SettingsKeys.size] = size;
      _values[SettingsKeys.bubbleX] = clamped.toString();
      notifyListeners();
      return;
    }
    await _db.transaction((txn) async {
      await _setInTxn(txn, SettingsKeys.size, size);
      await _setInTxn(txn, SettingsKeys.bubbleX, clamped.toString());
    });
    _values[SettingsKeys.size] = size;
    _values[SettingsKeys.bubbleX] = clamped.toString();
    notifyListeners();
  }

  Future<void> setBubblePosition(double x, double y, {required double screenWidth}) async {
    final clampedX = clampBubbleX(x, size, screenWidth);
    if (_db == null) {
      _values[SettingsKeys.bubbleX] = clampedX.toString();
      _values[SettingsKeys.bubbleY] = y.toString();
      notifyListeners();
      return;
    }
    await _db.transaction((txn) async {
      await _setInTxn(txn, SettingsKeys.bubbleX, clampedX.toString());
      await _setInTxn(txn, SettingsKeys.bubbleY, y.toString());
    });
    _values[SettingsKeys.bubbleX] = clampedX.toString();
    _values[SettingsKeys.bubbleY] = y.toString();
    notifyListeners();
  }

  Future<void> setOnboarded(bool value) => _set(SettingsKeys.onboarded, _fromBool(value));

  Future<void> setHintSeen(bool value) => _set(SettingsKeys.hintSeen, _fromBool(value));

  Future<void> setWifiOnlyDownloads(bool value) => _set(SettingsKeys.wifiOnlyDownloads, _fromBool(value));

  /// Copies the Phase 3 files-dir flag into SQLite once.
  Future<void> adoptLegacyOnboardedFile(bool legacyFileExists) async {
    if (legacyFileExists && !onboarded) {
      await setOnboarded(true);
    }
  }

  /// History rows created since local midnight. Phase 6 fills the table.
  Future<int> historyCountToday() async {
    if (_db == null) return 0;
    final start = DateTime.now();
    final midnight = DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    final row = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM history WHERE created_at >= ?',
      [midnight],
    );
    return row.first['c']! as int;
  }

  Future<void> _load() async {
    if (_db == null) return;
    _values.clear();
    final rows = await _db.query('settings');
    for (final row in rows) {
      _values[row['key']! as String] = row['value']! as String;
    }
    for (final key in SettingsKeys.all) {
      if (!_values.containsKey(key)) {
        await _set(key, _defaults[key]!);
      }
    }
  }

  Future<void> _set(String key, String value) async {
    final db = _db;
    if (db != null) {
      await _setInTxn(db, key, value);
    }
    _values[key] = value;
    notifyListeners();
  }

  Future<void> _setInTxn(DatabaseExecutor txn, String key, String value) {
    return txn.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  bool _bool(String key) => (_values[key] ?? _defaults[key]) == '1';

  double _double(String key) => double.tryParse(_values[key] ?? _defaults[key]!) ?? 0;

  static String _fromBool(bool v) => v ? '1' : '0';
}

class SettingsScope extends InheritedNotifier<SettingsStore> {
  const SettingsScope({required SettingsStore store, required super.child, super.key}) : super(notifier: store);

  static SettingsStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope is missing above this widget');
    return scope!.notifier!;
  }
}
