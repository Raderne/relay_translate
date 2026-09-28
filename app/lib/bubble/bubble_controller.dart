import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../data/settings_store.dart';
import 'bubble_tokens.dart';

/// Pure gesture logic for the in-app bubble (Chatter, Phase 5).
/// Port line-for-line to Kotlin `BubbleGesture.kt` in Phase 7.
enum BubblePhase { idle, pressing, dragging, menuOpen }

class BubbleController extends ChangeNotifier {
  BubbleController({
    required this.sizeCode,
    required this.snapEnabled,
    required double initialX,
    required double initialY,
    this.onTapMenu,
    this.onTranslateAll,
    this.onTranslateOne,
    this.onInteraction,
    this.onPositionPersist,
  }) : _x = initialX,
       _y = initialY;

  final String sizeCode;
  final bool snapEnabled;
  final VoidCallback? onTapMenu;
  final VoidCallback? onTranslateAll;
  final void Function(String? messageId)? onTranslateOne;
  final VoidCallback? onInteraction;
  final void Function(double x, double y)? onPositionPersist;

  BubblePhase phase = BubblePhase.idle;
  String? targetMessageId;
  double _x;
  double _y;
  Offset? _downGlobal;
  bool _holdFired = false;

  double get x => _x;
  double get y => _y;

  double get diameter => bubbleDiameter(sizeCode).toDouble();

  Size _viewport = Size.zero;
  Map<String, Rect> _incomingTargets = {};

  void setViewport(Size size) {
    if (_viewport == size) return;
    _viewport = size;
    _clampPosition();
    notifyListeners();
  }

  void setIncomingTargets(Map<String, Rect> targets) {
    _incomingTargets = targets;
  }

  void syncPosition(double x, double y) {
    _x = x;
    _y = y;
    _clampPosition();
    notifyListeners();
  }

  void dismissMenu() {
    if (phase == BubblePhase.menuOpen) {
      phase = BubblePhase.idle;
      notifyListeners();
    }
  }

  void pointerDown(Offset global) {
    onInteraction?.call();
    dismissMenu();
    _downGlobal = global;
    _holdFired = false;
    targetMessageId = null;
    phase = BubblePhase.pressing;
    notifyListeners();
  }

  void pointerMove(Offset global) {
    if (phase != BubblePhase.pressing && phase != BubblePhase.dragging) return;
    final down = _downGlobal;
    if (down == null) return;

    final delta = global - down;
    if (phase == BubblePhase.pressing && delta.distance >= BubbleTokens.moveThreshold) {
      phase = BubblePhase.dragging;
    }
    if (phase == BubblePhase.dragging) {
      _x = global.dx - diameter / 2;
      _y = global.dy - diameter / 2;
      _clampPosition();
      targetMessageId = _hitTest(global);
      notifyListeners();
    }
  }

  void pointerUp({required int elapsedMs, required Offset global}) {
    final down = _downGlobal;
    if (down == null) return;
    final moved = (global - down).distance;

    if (phase == BubblePhase.pressing) {
      if (!_holdFired && elapsedMs >= BubbleTokens.holdMs) {
        _holdFired = true;
        onTranslateAll?.call();
        _finishPointer();
        return;
      }
      if (!_holdFired && elapsedMs < BubbleTokens.holdMs && moved < BubbleTokens.moveThreshold) {
        phase = BubblePhase.menuOpen;
        onTapMenu?.call();
        notifyListeners();
        return;
      }
    }

    if (phase == BubblePhase.dragging) {
      if (snapEnabled) _applySnap();
      final id = targetMessageId;
      onTranslateOne?.call(id);
      onPositionPersist?.call(_x, _y);
      _finishPointer();
      return;
    }

    _finishPointer();
  }

  /// Call on each frame while [phase] is [BubblePhase.pressing].
  void tickPressing(int elapsedMs) {
    if (phase != BubblePhase.pressing || _holdFired) return;
    if (elapsedMs >= BubbleTokens.holdMs) {
      _holdFired = true;
      onTranslateAll?.call();
      _finishPointer();
    }
  }

  double ringProgress(int elapsedMs) {
    if (phase != BubblePhase.pressing) return 0;
    return math.min(1, elapsedMs / BubbleTokens.holdMs);
  }

  double get scale => switch (phase) {
    BubblePhase.pressing => BubbleTokens.scalePressing,
    BubblePhase.dragging => targetMessageId != null ? BubbleTokens.scaleTarget : BubbleTokens.scaleDragging,
    _ => 1,
  };

  bool get fillAccent => phase == BubblePhase.dragging && targetMessageId != null;

  void _finishPointer() {
    phase = BubblePhase.idle;
    targetMessageId = null;
    _downGlobal = null;
    notifyListeners();
  }

  void _applySnap() {
    if (_viewport.width <= 0) return;
    final centre = _x + diameter / 2;
    _x = centre < _viewport.width / 2
        ? BubbleTokens.snapInset
        : _viewport.width - diameter - BubbleTokens.snapInset;
    _clampPosition();
  }

  void _clampPosition() {
    if (_viewport.width <= 0 || _viewport.height <= 0) return;
    final maxX = math.max(0, _viewport.width - diameter);
    final maxY = math.max(
      BubbleTokens.topInset,
      _viewport.height - diameter - BubbleTokens.bottomInset,
    );
    _x = _x.clamp(0.0, maxX).toDouble();
    _y = _y.clamp(BubbleTokens.topInset, maxY).toDouble();
  }

  String? _hitTest(Offset global) {
    for (final entry in _incomingTargets.entries) {
      if (entry.value.contains(global)) return entry.key;
    }
    return null;
  }

  /// Menu placement from prototype: away from the nearest horizontal edge.
  Offset menuOrigin() {
    final centre = _x + diameter / 2;
    final onRight = centre >= _viewport.width / 2;
    final left = onRight ? _x - BubbleTokens.menuWidth - 8 : _x + diameter + 8;
    var top = _y;
    final maxTop = math.max(BubbleTokens.menuTopMin, _viewport.height - BubbleTokens.menuTopMaxOffset);
    top = top.clamp(BubbleTokens.menuTopMin, maxTop);
    return Offset(left, top);
  }

  Offset hintOrigin() {
    final centre = _x + diameter / 2;
    final onRight = centre >= _viewport.width / 2;
    final left = onRight ? _x - BubbleTokens.hintWidth - 8 : _x + diameter + 8;
    return Offset(left, _y);
  }
}
