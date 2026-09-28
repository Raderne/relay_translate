class ChatMessage {
  ChatMessage({
    required this.id,
    required this.time,
    required this.src,
    required this.outgoing,
    this.display,
    this.sourceLang,
    this.viaRelay = false,
    this.sentViaPair,
  });

  final String id;
  final String time;
  final String src;
  final bool outgoing;

  /// Shown text; when null, [src] is shown.
  String? display;
  String? sourceLang;
  bool viaRelay;
  String? sentViaPair;

  bool get incoming => !outgoing;
  bool get isTranslated => incoming && display != null;
  String get shown => display ?? src;
}
