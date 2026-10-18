class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.src,
    required this.tr,
    required this.srcLang,
    required this.targetLang,
    required this.appLabel,
    required this.createdAt,
    this.appPackage = '',
    this.ms,
    this.flagged = false,
    this.note,
  });

  final int id;
  final String src;
  final String tr;
  final String srcLang;
  final String targetLang;
  final String appLabel;
  final int createdAt;
  final String appPackage;

  /// Translate duration; null when a model download was part of it (Phase 10).
  final int? ms;

  /// Beta 👎 (Phase 10).
  final bool flagged;
  final String? note;

  static HistoryEntry fromMap(Map<String, Object?> row) => HistoryEntry(
    id: row['id']! as int,
    src: row['src']! as String,
    tr: row['tr']! as String,
    srcLang: row['src_lang']! as String,
    targetLang: row['target_lang']! as String,
    appLabel: row['app_label']! as String,
    createdAt: row['created_at']! as int,
    appPackage: row['app_package'] as String? ?? '',
    ms: row['ms'] as int?,
    flagged: row['flagged'] == 1,
    note: row['note'] as String?,
  );

  String metaLine() {
    final src = _codeLabel(srcLang);
    final tgt = _codeLabel(targetLang);
    return '$src → $tgt · $appLabel';
  }

  static String _codeLabel(String code) =>
      code == 'und' ? 'UND' : code.toUpperCase();
}
