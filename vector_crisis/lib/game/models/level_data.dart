import 'arrow_seed.dart';

class LevelData {
  final int id;
  final int rows;
  final int columns;
  final int difficulty;
  final String mechanicFocus;
  final int? targetMoves;
  final bool isChallenge;
  final bool isBreather;
  final List<ArrowSeed> arrows;

  const LevelData({
    required this.id,
    required this.rows,
    required this.columns,
    this.difficulty = 1,
    this.mechanicFocus = 'baseline',
    this.targetMoves,
    this.isChallenge = false,
    this.isBreather = false,
    required this.arrows,
  });

  /// Two attempts above the authored optimum keeps the puzzle fair while
  /// making blind tapping and unnecessary Rotator cycles meaningful.
  int? get moveLimit => targetMoves == null ? null : targetMoves! + 2;
}
