import 'dart:async';

import 'package:flutter/foundation.dart';

import '../bubble/bubble_tokens.dart';
import '../data/chatter_seed.dart';
import '../data/history_repository.dart';
import '../data/languages.dart';
import '../data/settings_store.dart';
import '../native/translator.dart';
import 'chatter_models.dart';

class ChatterSession extends ChangeNotifier {
  ChatterSession({
    required this.settings,
    required this.history,
    this.translator = const Translator(),
  }) : messages = kChatterSeed
      .map(
        (s) => ChatMessage(id: s.id, time: s.time, src: s.src, outgoing: s.outgoing),
      )
      .toList();

  final SettingsStore settings;
  final HistoryRepository history;
  final Translator translator;

  final List<ChatMessage> messages;
  String composerDraft = '';
  bool translating = false;
  double progress = 0;
  String? flashMessageId;
  String? detailMessageId;
  bool detailReplyMode = false;
  String replyDraft = '';
  String? replyTranslated;
  bool replyBusy = false;
  String? toastMessage;
  String? toastAction;
  VoidCallback? toastOnAction;

  List<ChatMessage> get incoming => messages.where((m) => m.incoming).toList();

  bool get allIncomingTranslated => incoming.isNotEmpty && incoming.every((m) => m.isTranslated);

  ChatMessage? messageById(String? id) => messages.where((m) => m.id == id).firstOrNull;

  void setDraft(String value) {
    composerDraft = value;
    notifyListeners();
  }

  void sendDraft() {
    final text = composerDraft.trim();
    if (text.isEmpty) return;
    messages.add(
      ChatMessage(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        time: _nowTime(),
        src: text,
        outgoing: true,
      ),
    );
    composerDraft = '';
    notifyListeners();
  }

  void pasteReply(String text) {
    composerDraft = text;
    detailMessageId = null;
    detailReplyMode = false;
    replyDraft = '';
    replyTranslated = null;
    notifyListeners();
    _toast('Pasted into Chatter · tap send');
  }

  void openDetail(String id) {
    detailMessageId = id;
    detailReplyMode = false;
    replyDraft = '';
    replyTranslated = null;
    notifyListeners();
  }

  void closeDetail() {
    detailMessageId = null;
    detailReplyMode = false;
    notifyListeners();
  }

  void startReply() {
    detailReplyMode = true;
    notifyListeners();
  }

  void setReplyDraft(String value) {
    replyDraft = value;
    replyTranslated = null;
    notifyListeners();
  }

  void markCopied() => _toast('Copied');

  void revertMessage(String id) {
    final m = messageById(id);
    if (m == null || !m.incoming) return;
    m.display = null;
    m.sourceLang = null;
    notifyListeners();
  }

  void revertAllIncoming() {
    for (final m in incoming) {
      m.display = null;
      m.sourceLang = null;
    }
    notifyListeners();
  }

  Future<void> translateAll() async {
    if (incoming.isEmpty) return;
    if (allIncomingTranslated) {
      revertAllIncoming();
      _toast('Showing original text');
      return;
    }

    translating = true;
    progress = 0;
    notifyListeners();
    final started = DateTime.now();
    unawaited(_animateProgress());

    try {
      final target = settings.targetLang;
      final texts = incoming.map((m) => m.src).toList();
      final results = await translator.translate(texts, target, wifiOnly: settings.wifiOnlyDownloads);
      final elapsed = DateTime.now().difference(started);
      if (elapsed < const Duration(milliseconds: BubbleTokens.translateAllMinMs)) {
        await Future<void>.delayed(
          const Duration(milliseconds: BubbleTokens.translateAllMinMs) - elapsed,
        );
      }
      var anyUnd = false;
      for (var i = 0; i < incoming.length; i++) {
        final r = results[i];
        final m = incoming[i];
        if (r.undetected) {
          anyUnd = true;
          continue;
        }
        m.display = r.text;
        m.sourceLang = r.source;
        await history.logTranslation(
          src: m.src,
          tr: r.text,
          srcLang: r.source,
          targetLang: target,
          ms: elapsed.inMilliseconds,
        );
      }
      final detected = results.where((r) => !r.undetected).map((r) => r.source).toSet();
      final srcLabel = detected.length == 1 ? _langLabel(detected.first) : 'Mixed';
      final tgtLabel = langName(target);
      if (anyUnd) {
        _toast("Couldn't detect language");
      } else {
        _toast(
          '${incoming.length} messages · $srcLabel → $tgtLabel',
          action: 'Show original',
          onAction: revertAllIncoming,
        );
      }
    } on TranslateException catch (e) {
      _toast(_errorLabel(e));
    } finally {
      translating = false;
      progress = 0;
      notifyListeners();
    }
  }

  Future<void> translateOne(String? id) async {
    if (id == null) return;
    final m = messageById(id);
    if (m == null || !m.incoming) return;
    if (m.isTranslated) {
      openDetail(id);
      return;
    }

    final started = DateTime.now();
    try {
      final target = settings.targetLang;
      final results = await translator.translate([m.src], target, wifiOnly: settings.wifiOnlyDownloads);
      final r = results.single;
      if (r.undetected) {
        _toast("Couldn't detect language");
        return;
      }
      m.display = r.text;
      m.sourceLang = r.source;
      flashMessageId = id;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: BubbleTokens.flashMs));
      flashMessageId = null;
      final elapsed = DateTime.now().difference(started);
      await history.logTranslation(
        src: m.src,
        tr: r.text,
        srcLang: r.source,
        targetLang: target,
        ms: elapsed.inMilliseconds,
      );
      _toast(
        'Translated · ${_langLabel(r.source)} → ${langName(target)}',
        action: 'Undo',
        onAction: () => revertMessage(id),
      );
      notifyListeners();
    } on TranslateException catch (e) {
      _toast(_errorLabel(e));
    }
  }

  Future<void> translateReply() async {
    final m = messageById(detailMessageId);
    if (m == null || m.sourceLang == null) return;
    replyBusy = true;
    replyTranslated = null;
    notifyListeners();
    try {
      final results = await translator.translate(
        [replyDraft],
        m.sourceLang!,
        wifiOnly: settings.wifiOnlyDownloads,
      );
      replyTranslated = results.single.text;
    } on TranslateException catch (e) {
      _toast(_errorLabel(e));
    } finally {
      replyBusy = false;
      notifyListeners();
    }
  }

  Future<void> _animateProgress() async {
    const steps = 20;
    for (var i = 0; i <= steps; i++) {
      if (!translating) return;
      progress = i / steps;
      notifyListeners();
      await Future<void>.delayed(
        Duration(milliseconds: BubbleTokens.progressBarMs ~/ steps),
      );
    }
  }

  void _toast(String message, {String? action, VoidCallback? onAction}) {
    toastMessage = message;
    toastAction = action;
    toastOnAction = onAction;
    notifyListeners();
    Future.delayed(RelayToastDuration.duration, () {
      if (toastMessage == message) {
        toastMessage = null;
        toastAction = null;
        toastOnAction = null;
        notifyListeners();
      }
    });
  }

  String _langLabel(String code) => code == 'und' ? 'Unknown' : langName(code);

  String _errorLabel(TranslateException e) {
    if (e.code == TranslateException.modelDownloadFailed || e.code == TranslateException.noNetwork) {
      return "Couldn't translate · Retry";
    }
    return "Couldn't translate · Retry";
  }

  String _nowTime() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }
}

/// Avoid importing material in session — duplicate toast duration.
abstract final class RelayToastDuration {
  static const duration = Duration(milliseconds: 3500);
}
