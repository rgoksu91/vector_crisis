import 'dart:math' as math;

enum ArrowDirection { up, right, down, left }

extension ArrowDirectionX on ArrowDirection {
  int get rowDelta => switch (this) {
    ArrowDirection.up => -1,
    ArrowDirection.down => 1,
    _ => 0,
  };

  int get columnDelta => switch (this) {
    ArrowDirection.left => -1,
    ArrowDirection.right => 1,
    _ => 0,
  };

  double get radians => switch (this) {
    ArrowDirection.right => 0,
    ArrowDirection.down => math.pi / 2,
    ArrowDirection.left => math.pi,
    ArrowDirection.up => -math.pi / 2,
  };

  ArrowDirection get clockwise => switch (this) {
    ArrowDirection.up => ArrowDirection.right,
    ArrowDirection.right => ArrowDirection.down,
    ArrowDirection.down => ArrowDirection.left,
    ArrowDirection.left => ArrowDirection.up,
  };
}
