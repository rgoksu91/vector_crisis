import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) =>
                CustomPaint(painter: _BackgroundPainter(_controller.value)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;

  const _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * (0.25 + 0.08 * math.sin(progress * math.pi * 2)),
                size.height * 0.22,
              ),
              radius: size.width * 0.85,
            ),
          );
    canvas.drawRect(Offset.zero & size, glowPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const spacing = 42.0;
    final drift = progress * spacing;
    for (double x = -spacing + drift; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = -spacing + drift; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final nodePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.3);
    for (var i = 0; i < 7; i++) {
      final angle = progress * math.pi * 2 + i * 1.7;
      final center = Offset(
        size.width * (0.5 + 0.48 * math.sin(angle * 0.43 + i)),
        size.height * (0.5 + 0.46 * math.cos(angle * 0.31 + i)),
      );
      canvas.drawCircle(center, 2.2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
