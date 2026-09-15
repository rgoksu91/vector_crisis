import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../arrow_chaos_game.dart';
import '../models/arrow_direction.dart';
import '../models/arrow_seed.dart';
import '../models/arrow_type.dart';

class ArrowComponent extends PositionComponent
    with TapCallbacks, HasGameReference<ArrowChaosGame> {
  final int arrowId;
  final int row;
  final int column;
  final ArrowType type;

  ArrowDirection direction;
  bool frozen;
  bool isMoving = false;

  Vector2? _flightTarget;
  VoidCallback? _flightDone;
  double _shakeRemaining = 0;
  double _shakeElapsed = 0;
  late Vector2 _restingPosition;
  double _hintRemaining = 0;
  double _hintElapsed = 0;
  double _explodeRemaining = 0;
  double _explodeElapsed = 0;
  VoidCallback? _explodeDone;

  ArrowComponent({
    required this.arrowId,
    required ArrowSeed seed,
    required double cellSize,
  }) : row = seed.row,
       column = seed.column,
       direction = seed.direction,
       type = seed.type,
       frozen = seed.type == ArrowType.frozen,
       super(
         position: Vector2(seed.column * cellSize, seed.row * cellSize),
         size: Vector2.all(cellSize),
         priority: 10,
       ) {
    _restingPosition = position.clone();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isMoving) return;
    game.onArrowTapped(this);
  }

  void rotateClockwise() {
    direction = direction.clockwise;
    _hintRemaining = 0.28;
    _hintElapsed = 0;
  }

  void thaw() {
    if (!frozen) return;
    frozen = false;
    _hintRemaining = 0.45;
    _hintElapsed = 0;
  }

  void playBlocked() {
    if (isMoving) return;
    _restingPosition = position.clone();
    _shakeRemaining = 0.22;
    _shakeElapsed = 0;
  }

  void playHint() {
    _hintRemaining = 1.1;
    _hintElapsed = 0;
  }

  void startFlight(Vector2 target, VoidCallback onDone) {
    isMoving = true;
    _flightTarget = target;
    _flightDone = onDone;
    _shakeRemaining = 0;
  }

  void startExplosion(VoidCallback onDone) {
    isMoving = true;
    _explodeRemaining = 0.22;
    _explodeElapsed = 0;
    _explodeDone = onDone;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _updateFlight(dt);
    _updateShake(dt);
    _updateHint(dt);
    _updateExplosion(dt);
  }

  void _updateFlight(double dt) {
    final target = _flightTarget;
    if (target == null) return;

    final dx = target.x - position.x;
    final dy = target.y - position.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final speed = math.max(900.0, size.x * 13).toDouble();
    final step = speed * dt;

    if (distance <= step || distance < 0.5) {
      position.setFrom(target);
      _flightTarget = null;
      final done = _flightDone;
      _flightDone = null;
      done?.call();
      return;
    }

    position.add(Vector2(dx / distance * step, dy / distance * step));
  }

  void _updateShake(double dt) {
    if (_shakeRemaining <= 0) return;

    _shakeRemaining -= dt;
    _shakeElapsed += dt;
    final magnitude = size.x * 0.07;
    final wave = math.sin(_shakeElapsed * 52) * magnitude;
    position.setValues(
      _restingPosition.x + direction.columnDelta * wave,
      _restingPosition.y + direction.rowDelta * wave,
    );

    if (_shakeRemaining <= 0) {
      position.setFrom(_restingPosition);
    }
  }

  void _updateHint(double dt) {
    if (_hintRemaining <= 0) return;
    _hintRemaining -= dt;
    _hintElapsed += dt;
  }

  void _updateExplosion(double dt) {
    if (_explodeRemaining <= 0) return;
    _explodeRemaining -= dt;
    _explodeElapsed += dt;
    if (_explodeRemaining <= 0) {
      final done = _explodeDone;
      _explodeDone = null;
      done?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    final hintPulse = _hintRemaining > 0
        ? 1 + math.sin(_hintElapsed * 12).abs() * 0.08
        : 1.0;
    final explosionProgress = _explodeElapsed <= 0
        ? 0.0
        : (_explodeElapsed / 0.22).clamp(0.0, 1.0).toDouble();
    final explosionScale = 1 - explosionProgress * 0.65;
    final visualScale = hintPulse * explosionScale;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(visualScale, visualScale);
    canvas.translate(-size.x / 2, -size.y / 2);

    final tileRect = Rect.fromLTWH(
      size.x * 0.08,
      size.y * 0.08,
      size.x * 0.84,
      size.y * 0.84,
    );

    final baseColor = frozen
        ? const Color(0xFF8EDCFF)
        : switch (type) {
            ArrowType.normal => const Color(0xFF6677FF),
            ArrowType.rotator => const Color(0xFFFFA24A),
            ArrowType.frozen => const Color(0xFF5AAFE8),
            ArrowType.bomb => const Color(0xFFFF5F6D),
          };

    canvas.drawShadow(
      Path()..addRRect(
        RRect.fromRectAndRadius(tileRect, const Radius.circular(15)),
      ),
      const Color(0x88000000),
      8,
      false,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(tileRect, const Radius.circular(15)),
      Paint()..color = baseColor.withValues(alpha: 0.95),
    );

    if (_hintRemaining > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(tileRect.inflate(3), const Radius.circular(18)),
        Paint()
          ..color = const Color(0xFFFFF3A6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    _drawArrow(canvas);
    _drawBadge(canvas);

    if (frozen) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(tileRect, const Radius.circular(15)),
        Paint()..color = const Color(0x448EE8FF),
      );
    }

    canvas.restore();
  }

  void _drawArrow(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(direction.radians);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shaftHeight = size.y * 0.10;
    final shaftLeft = -size.x * 0.20;
    final shaftRight = size.x * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(shaftLeft, -shaftHeight / 2, shaftRight, shaftHeight / 2),
        Radius.circular(shaftHeight / 2),
      ),
      paint,
    );

    final head = Path()
      ..moveTo(size.x * 0.24, 0)
      ..lineTo(size.x * 0.06, -size.y * 0.15)
      ..lineTo(size.x * 0.06, size.y * 0.15)
      ..close();
    canvas.drawPath(head, paint);
    canvas.restore();
  }

  void _drawBadge(Canvas canvas) {
    if (type == ArrowType.normal) return;

    final symbol = type.badge;
    final painter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.x * 0.22,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(size.x * 0.69 - painter.width / 2, size.y * 0.12),
    );
  }
}
