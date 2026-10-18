import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/detail/cross_app_detail.dart';
import 'package:relay_translate/native/translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final detailCalls = <MethodCall>[];
  final translateCalls = <MethodCall>[];
  String? clipboard;

  const args = DetailArgs(
    src: 'Are you free tonight?',
    tr: 'Tu es libre ce soir ?',
    source: 'en',
    target: 'fr',
    appLabel: 'WhatsApp',
    appPackage: 'com.whatsapp',
    wifiOnly: false,
  );

  setUp(() {
    detailCalls.clear();
    translateCalls.clear();
    clipboard = null;
    messenger.setMockMethodCallHandler(DetailBridge.channel, (call) async {
      detailCalls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String;
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(DetailBridge.channel, null);
    messenger.setMockMethodCallHandler(Translator.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  void mockTranslate(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      translateCalls.add(call);
      return handler(call);
    });
  }

  test('DetailArgs reads the map DetailActivity sends', () {
    final parsed = DetailArgs.fromMap({
      'src': 'Hi',
      'tr': 'Salut',
      'source': 'en',
      'target': 'fr',
      'appLabel': 'Telegram',
      'appPackage': 'org.telegram.messenger',
      'wifiOnly': true,
    });
    expect(parsed.appLabel, 'Telegram');
    expect(parsed.source, 'en');
    expect(parsed.wifiOnly, isTrue);
  });

  test('translateReply translates the draft back into the message language', () async {
    mockTranslate((_) => [
      {'text': "Yes, I'm free", 'source': 'fr'},
    ]);
    final s = CrossAppDetailSession(args: args)
      ..startReply()
      ..setReplyDraft('Oui, je suis libre');

    await s.translateReply();

    expect(translateCalls.single.arguments, {
      'texts': ['Oui, je suis libre'],
      'target': 'en',
      'wifiOnly': false,
    });
    expect(s.replyTranslated, "Yes, I'm free");
    expect(s.replyBusy, isFalse);
  });

  test('editing the draft drops the old translation', () async {
    mockTranslate((_) => [
      {'text': 'Yes', 'source': 'fr'},
    ]);
    final s = CrossAppDetailSession(args: args)..setReplyDraft('Oui');
    await s.translateReply();
    s.setReplyDraft('Oui !');
    expect(s.replyTranslated, isNull);
  });

  test('paste hands the translated reply to native', () async {
    mockTranslate((_) => [
      {'text': 'Yes', 'source': 'fr'},
    ]);
    final s = CrossAppDetailSession(args: args)..setReplyDraft('Oui');
    await s.translateReply();
    await s.paste();
    expect(detailCalls.single.method, 'paste');
    expect(detailCalls.single.arguments, {'text': 'Yes'});
  });

  test('paste does nothing before the reply is translated', () async {
    final s = CrossAppDetailSession(args: args)..setReplyDraft('Oui');
    await s.paste();
    expect(detailCalls, isEmpty);
  });

  test('a failed reply translation toasts and clears busy', () async {
    messenger.setMockMethodCallHandler(Translator.channel, (call) async {
      throw PlatformException(code: TranslateException.translateFailed);
    });
    final s = CrossAppDetailSession(args: args)..setReplyDraft('Oui');
    await s.translateReply();
    expect(s.replyBusy, isFalse);
    expect(s.replyTranslated, isNull);
    expect(detailCalls.single.method, 'toast');
    expect(detailCalls.single.arguments, {'message': "Couldn't translate · Retry"});
  });

  test('copy puts the translation on the clipboard and toasts', () async {
    final s = CrossAppDetailSession(args: args);
    await s.copy();
    expect(clipboard, 'Tu es libre ce soir ?');
    expect(detailCalls.single.method, 'toast');
    expect(detailCalls.single.arguments, {'message': 'Copied'});
  });

  test('show original and close both close the sheet', () async {
    final s = CrossAppDetailSession(args: args);
    await s.showOriginal();
    await s.close();
    expect(detailCalls.map((c) => c.method), ['close', 'close']);
  });
}
