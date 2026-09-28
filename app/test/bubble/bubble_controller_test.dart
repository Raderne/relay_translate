import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_translate/bubble/bubble_controller.dart';
import 'package:relay_translate/bubble/bubble_tokens.dart';

void main() {
  BubbleController controller({
    double x = 100,
    double y = 200,
    void Function()? onTapMenu,
    void Function()? onTranslateAll,
    void Function(String? id)? onTranslateOne,
  }) {
    return BubbleController(
      sizeCode: 'M',
      snapEnabled: true,
      initialX: x,
      initialY: y,
      onTapMenu: onTapMenu,
      onTranslateAll: onTranslateAll,
      onTranslateOne: onTranslateOne,
    );
  }

  const viewport = Size(400, 800);
  const down = Offset(120, 220);

  group('BubbleController', () {
    test('tap opens menu', () {
      var menu = false;
      final c = controller(onTapMenu: () => menu = true);
      c.setViewport(viewport);
      c.pointerDown(down);
      c.pointerUp(elapsedMs: 100, global: down);
      expect(menu, isTrue);
      expect(c.phase, BubblePhase.menuOpen);
    });

    test('hold 550 ms triggers translateAll', () {
      var all = false;
      final c = controller(onTranslateAll: () => all = true);
      c.setViewport(viewport);
      c.pointerDown(down);
      c.tickPressing(BubbleTokens.holdMs);
      expect(all, isTrue);
      expect(c.phase, BubblePhase.idle);
    });

    test('pointerUp after hold elapsed triggers translateAll', () {
      var all = false;
      final c = controller(onTranslateAll: () => all = true);
      c.setViewport(viewport);
      c.pointerDown(down);
      c.pointerUp(elapsedMs: BubbleTokens.holdMs, global: down);
      expect(all, isTrue);
    });

    test('5 px move stays pressing; 7 px starts dragging', () {
      final c = controller();
      c.setViewport(viewport);
      c.pointerDown(down);
      c.pointerMove(down + const Offset(5, 0));
      expect(c.phase, BubblePhase.pressing);
      c.pointerMove(down + const Offset(7, 0));
      expect(c.phase, BubblePhase.dragging);
    });

    test('snap left when bubble centre is in left half', () {
      final c = controller(x: 20);
      c.setViewport(viewport);
      const start = Offset(30, 220);
      c.pointerDown(start);
      c.pointerMove(start + const Offset(8, 0));
      c.pointerUp(elapsedMs: 100, global: start + const Offset(8, 0));
      expect(c.x, BubbleTokens.snapInset);
    });

    test('snap right when bubble centre is in right half', () {
      final c = controller(x: 300);
      c.setViewport(viewport);
      const start = Offset(320, 220);
      c.pointerDown(start);
      c.pointerMove(start + const Offset(8, 0));
      c.pointerUp(elapsedMs: 100, global: start + const Offset(8, 0));
      final diameter = c.diameter;
      expect(c.x, viewport.width - diameter - BubbleTokens.snapInset);
    });

    test('clamp keeps bubble inside viewport', () {
      final c = controller(x: -50, y: 10);
      c.setViewport(viewport);
      expect(c.y, greaterThanOrEqualTo(BubbleTokens.topInset));
      expect(c.x, greaterThanOrEqualTo(0));
    });

    test('drop with no incoming target passes null id', () {
      String? dropped = 'unset';
      final c = controller(onTranslateOne: (id) => dropped = id);
      c.setViewport(viewport);
      c.setIncomingTargets({});
      c.pointerDown(down);
      c.pointerMove(down + const Offset(8, 0));
      c.pointerUp(elapsedMs: 100, global: down + const Offset(8, 0));
      expect(dropped, isNull);
    });

    test('hit-test only incoming rects', () {
      var id = 'unset';
      final c = controller(onTranslateOne: (v) => id = v ?? 'null');
      c.setViewport(viewport);
      const hit = Offset(50, 50);
      c.setIncomingTargets({'m3': const Rect.fromLTWH(40, 40, 80, 40)});
      c.pointerDown(hit);
      c.pointerMove(hit + const Offset(8, 0));
      expect(c.targetMessageId, 'm3');
      c.pointerUp(elapsedMs: 100, global: hit + const Offset(8, 0));
      expect(id, 'm3');
    });
  });
}
