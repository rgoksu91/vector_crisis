import 'arrow_direction.dart';
import 'arrow_type.dart';

class ArrowSeed {
  final int row;
  final int column;
  final ArrowDirection direction;
  final ArrowType type;

  const ArrowSeed({
    required this.row,
    required this.column,
    required this.direction,
    this.type = ArrowType.normal,
  });

  const ArrowSeed.normal(this.row, this.column, this.direction)
    : type = ArrowType.normal;

  const ArrowSeed.rotator(this.row, this.column, this.direction)
    : type = ArrowType.rotator;

  const ArrowSeed.frozen(this.row, this.column, this.direction)
    : type = ArrowType.frozen;

  const ArrowSeed.bomb(this.row, this.column, this.direction)
    : type = ArrowType.bomb;

  const ArrowSeed.stone(this.row, this.column, this.direction)
    : type = ArrowType.stone;

  const ArrowSeed.gear(this.row, this.column, this.direction)
    : type = ArrowType.gear;
}
