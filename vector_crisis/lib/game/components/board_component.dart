import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BoardComponent extends PositionComponent {
  final int rows;
  final int columns;
  final double cellSize;

  BoardComponent({
    required this.rows,
    required this.columns,
    required this.cellSize,
  }) : super(size: Vector2(columns * cellSize, rows * cellSize), priority: 0);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final boardRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(24)),
      Paint()..color = const Color(0x221A2140),
    );

    final cellPaint = Paint()
      ..color = const Color(0x184B5A92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final inset = cellSize * 0.08;
        final rect = Rect.fromLTWH(
          column * cellSize + inset,
          row * cellSize + inset,
          cellSize - inset * 2,
          cellSize - inset * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
          cellPaint,
        );
      }
    }
  }
}
