import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A landed Stone: a permanent block that stops every arrow's path.
class WallComponent extends PositionComponent {
  double _settle = 0.18;

  WallComponent({
    required int row,
    required int column,
    required double cellSize,
  }) : super(
         position: Vector2(column * cellSize, row * cellSize),
         size: Vector2.all(cellSize),
         priority: 5,
       );

  @override
  void update(double dt) {
    super.update(dt);
    if (_settle > 0) _settle -= dt;
  }

  @override
  void render(Canvas canvas) {
    final squash = _settle > 0 ? 1 + _settle * 0.6 : 1.0;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(squash, 2 - squash);
    canvas.translate(-size.x / 2, -size.y / 2);

    final rect = Rect.fromLTWH(
      size.x * 0.06,
      size.y * 0.06,
      size.x * 0.88,
      size.y * 0.88,
    );
    final block = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(block, Paint()..color = const Color(0xFF4A4658));

    // Two offset courses of brick read as "wall" even at small cell sizes.
    final mortar = Paint()
      ..color = const Color(0xFF2E2B38)
      ..strokeWidth = 2;
    final midY = rect.center.dy;
    canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), mortar);
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.5, rect.top),
      Offset(rect.left + rect.width * 0.5, midY),
      mortar,
    );
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.25, midY),
      Offset(rect.left + rect.width * 0.25, rect.bottom),
      mortar,
    );
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.75, midY),
      Offset(rect.left + rect.width * 0.75, rect.bottom),
      mortar,
    );
    canvas.drawRRect(
      block,
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }
}
