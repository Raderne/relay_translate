import 'dart:async';

import 'package:flutter/material.dart';

import '../data/languages.dart';
import '../native/translator.dart';

/// Phase 1 throwaway: paste messages (one per line), pick a target, translate,
/// see per-message source + latency. Exists to get an early read on ML Kit
/// quality before testers do. Replaced by the real screens from Phase 2 on.
class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key, this.translator = const Translator()});

  final Translator translator;

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  static const _sample = '''Hey! Did you make it to London okay?
ok see u
lol 😂
brb, grabbing a coffee
Can u send me the address again pls?
Merci beaucoup, à demain !
that's sooo annoying tbh''';

  final _input = TextEditingController(text: _sample);
  String _target = kLangs.first.code;
  bool _wifiOnly = true;
  ModelStatus? _status;
  Timer? _poll;
  List<Translation>? _results;
  int? _ms;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    try {
      final s = await widget.translator.modelStatus(_target);
      if (!mounted) return;
      setState(() => _status = s);
      _poll?.cancel();
      if (s == ModelStatus.downloading) {
        _poll = Timer(const Duration(milliseconds: 500), _refreshStatus);
      }
    } on TranslateException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on TranslateException catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
      unawaited(_refreshStatus());
    }
  }

  Future<void> _translate() => _run(() async {
    final texts = _input.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    // Kick status polling so the "Downloading…" line shows while the first model lands.
    unawaited(Future<void>.delayed(const Duration(milliseconds: 200), _refreshStatus));
    final sw = Stopwatch()..start();
    final out = await widget.translator.translate(texts, _target, wifiOnly: _wifiOnly);
    sw.stop();
    setState(() {
      _results = out;
      _ms = sw.elapsedMilliseconds;
    });
  });

  Future<void> _download() => _run(() async {
    unawaited(Future<void>.delayed(const Duration(milliseconds: 200), _refreshStatus));
    await widget.translator.ensureModel(_target, wifiOnly: _wifiOnly);
  });

  Future<void> _delete() => _run(() => widget.translator.deleteModel(_target));

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('ML Kit spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _target,
                  decoration: const InputDecoration(labelText: 'Translate to'),
                  items: [
                    for (final l in [...kLangs, kEnglish])
                      DropdownMenuItem(value: l.code, child: Text('${l.flag} ${l.name}')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _target = v;
                      _results = null;
                    });
                    _refreshStatus();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text('Wi-Fi only'),
                  Switch(value: _wifiOnly, onChanged: (v) => setState(() => _wifiOnly = v)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(_statusLine(), key: const Key('status'))),
              if (_status == ModelStatus.missing)
                TextButton(onPressed: _busy ? null : _download, child: const Text('Download')),
              if (_status == ModelStatus.ready)
                TextButton(onPressed: _busy ? null : _delete, child: const Text('Delete')),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Messages (one per line)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _translate,
            child: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Translate'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, key: const Key('error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (results != null) ...[
            const SizedBox(height: 16),
            Text('${results.length} messages in $_ms ms', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final r in results)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text(r.undetected ? '?' : r.source.toUpperCase()),
                title: Text(r.text),
                subtitle: r.undetected ? const Text("Couldn't detect language") : null,
              ),
          ],
        ],
      ),
    );
  }

  String _statusLine() => switch (_status) {
    null => 'Checking model…',
    ModelStatus.ready => '${langName(_target)} model: works offline',
    ModelStatus.downloading => 'Downloading ${langName(_target)} (~30 MB)…',
    ModelStatus.missing => '${langName(_target)} model: not downloaded',
  };
}
