import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no hex color or font name outside theme/', () {
    final hex = RegExp(r'#[0-9A-Fa-f]{3,8}\b|Color\(0x|Color\.from');
    final font = RegExp('Barlow');
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.contains('/theme/')) continue;
      final text = entity.readAsStringSync();
      if (hex.hasMatch(text) || font.hasMatch(text)) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });
}
