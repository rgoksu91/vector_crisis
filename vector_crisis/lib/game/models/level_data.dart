import '../logic/board_rules.dart';
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

  /// Cells that block every ray. Shipped levels start without any; the game
  /// uses this to hand a position with landed Stones to the solver.
  final List<BoardCell> walls;

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
    this.walls = const [],
  });

  /// Moves the player may waste before the level is lost.
  ///
  /// Long boards get a slightly wider budget so a single slip near the end is
  /// not fatal, but the allowance stays around a tenth of the optimum, which
  /// is what makes wasted Rotator turns and mistimed blasts matter at all.
  int get moveSlack {
    final target = targetMoves;
    if (target == null) return 0;
    return (2 + target ~/ 14).clamp(2, 4);
  }

  /// Best score for the level; anything beyond it fails the run.
  int? get moveLimit => targetMoves == null ? null : targetMoves! + moveSlack;

  /// Upper bound for a two-star finish. Three stars require the optimum.
  int? get twoStarMoves =>
      targetMoves == null ? null : targetMoves! + (moveSlack + 1) ~/ 2;
}
