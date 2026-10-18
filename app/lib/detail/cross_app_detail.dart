import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/history_repository.dart';
import '../native/translator.dart';

/// What `DetailActivity` was opened with: one translated message from another app (Phase 9).
class DetailArgs {
  const DetailArgs({
    required this.src,
    required this.tr,
    required this.source,
    required this.target,
    required this.appLabel,
    required this.appPackage,
    required this.wifiOnly,
  });

  factory DetailArgs.fromMap(Map<Object?, Object?> m) => DetailArgs(
    src: m['src']! as String,
    tr: m['tr']! as String,
    source: m['source']! as String,
    target: m['target']! as String,
    appLabel: m['appLabel']! as String,
    appPackage: m['appPackage']! as String,
    wifiOnly: m['wifiOnly']! as bool,
  );

  final String src;
  final String tr;
  final String source;
  final String target;
  final String appLabel;
  final String appPackage;
  final bool wifiOnly;
}

/// `relay/detail` → `DetailActivity.kt`.
class DetailBridge {
  const DetailBridge();

  static const channel = MethodChannel('relay/detail');

  Future<DetailArgs> args() async =>
      DetailArgs.fromMap((await channel.invokeMethod<Map<Object?, Object?>>('args'))!);

  /// Closes the sheet; the accessibility service pastes into [DetailArgs.appPackage]. Never sends.
  Future<void> paste(String text) => channel.invokeMethod<void>('paste', {'text': text});

  Future<void> toast(String message) => channel.invokeMethod<void>('toast', {'message': message});

  Future<void> close() => channel.invokeMethod<void>('close');
}

/// Detail sheet state over another app. Same reply flow as `ChatterSession`; the actions go to native.
class CrossAppDetailSession extends ChangeNotifier {
  CrossAppDetailSession({
    required this.args,
    this.translator = const Translator(),
    this.bridge = const DetailBridge(),
    this.history,
  });

  final DetailArgs args;
  final Translator translator;
  final DetailBridge bridge;

  /// Beta only (Phase 10): where 👎 goes. Null → no flag button.
  final HistoryRepository? history;
  bool flagged = false;

  bool replyMode = false;
  String replyDraft = '';
  String? replyTranslated;
  bool replyBusy = false;

  void startReply() {
    replyMode = true;
    notifyListeners();
  }

  void setReplyDraft(String value) {
    replyDraft = value;
    replyTranslated = null;
    notifyListeners();
  }

  /// Reply is written in [DetailArgs.target]; it goes back into the message's language.
  Future<void> translateReply() async {
    replyBusy = true;
    replyTranslated = null;
    notifyListeners();
    try {
      final results = await translator.translate([replyDraft], args.source, wifiOnly: args.wifiOnly);
      replyTranslated = results.single.text;
    } on TranslateException {
      await bridge.toast("Couldn't translate · Retry");
    } finally {
      replyBusy = false;
      notifyListeners();
    }
  }

  Future<void> setFlag(bool value) async {
    flagged = value;
    notifyListeners();
    await _saveFlag(note: null);
  }

  Future<void> setNote(String note) async {
    if (!flagged) return;
    await _saveFlag(note: note);
  }

  Future<void> _saveFlag({required String? note}) async => history?.setFlag(
    src: args.src,
    tr: args.tr,
    srcLang: args.source,
    targetLang: args.target,
    appPackage: args.appPackage,
    appLabel: args.appLabel,
    flagged: flagged,
    note: note,
  );

  Future<void> paste() async {
    final text = replyTranslated;
    if (text == null) return;
    await bridge.paste(text);
  }

  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: args.tr));
    await bridge.toast('Copied');
  }

  /// The translated boxes are already gone (cleared when the box was tapped), so this just closes.
  Future<void> showOriginal() => bridge.close();

  Future<void> close() => bridge.close();
}
