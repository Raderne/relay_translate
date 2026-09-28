class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.src,
    required this.tr,
    required this.srcLang,
    required this.targetLang,
    required this.appLabel,
    required this.createdAt,
  });

  final int id;
  final String src;
  final String tr;
  final String srcLang;
  final String targetLang;
  final String appLabel;
  final int createdAt;

  static HistoryEntry fromMap(Map<String, Object?> row) => HistoryEntry(
    id: row['id']! as int,
    src: row['src']! as String,
    tr: row['tr']! as String,
    srcLang: row['src_lang']! as String,
    targetLang: row['target_lang']! as String,
    appLabel: row['app_label']! as String,
    createdAt: row['created_at']! as int,
  );

  String metaLine() {
    final src = _codeLabel(srcLang);
    final tgt = _codeLabel(targetLang);
    return '$src → $tgt · $appLabel';
  }

  static String _codeLabel(String code) =>
      code == 'und' ? 'UND' : code.toUpperCase();
}
