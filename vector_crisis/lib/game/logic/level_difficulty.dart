import 'dart:math';

import 'board_engine.dart';
import 'level_solver.dart';
import '../models/arrow_type.dart';
import '../models/level_data.dart';

/// How a board holds up against players who do not plan far ahead.
///
/// Without Stones every mechanic is monotone and a board can only be lost on
/// move economy. Stones add real dead ends: a wall dropped in the wrong place
/// jams the board for good. These figures say how often each kind of player
/// wastes moves or walks into such a jam.
class DifficultyReport {
  final int minimumMoves;
  final int moveLimit;

  /// Taps uniformly at random among everything that reacts to a tap.
  final double carelessOptimalRate;
  final double carelessFailureRate;

  /// Always exits when something can exit, and otherwise taps anything that
  /// reacts — the natural way a person plays.
  final double sensibleOptimalRate;
  final double sensibleFailureRate;
  final double sensibleStuckRate;
  final double sensibleAverageMoves;
  final int sensibleWorstMoves;

  /// Plays like the sensible player but never slides a Stone onto a ray that
  /// is open right now, unless nothing else is left. Beating this player
  /// takes more than one move of lookahead.
  final double carefulOptimalRate;
  final double carefulFailureRate;
  final double carefulStuckRate;

  /// Plays the rules a person works out after a few levels: clear whatever can
  /// leave, keep Stones for last and only slide them somewhere harmless, wait
  /// for the Gears rather than turn a Rotator, and never waste a turn. If this
  /// player can three-star a level, the level has no real decision in it.
  final double strategistOptimalRate;
  final double strategistFailureRate;
  final double strategistAverageMoves;

  const DifficultyReport({
    required this.minimumMoves,
    required this.moveLimit,
    required this.carelessOptimalRate,
    required this.carelessFailureRate,
    required this.sensibleOptimalRate,
    required this.sensibleFailureRate,
    required this.sensibleStuckRate,
    required this.sensibleAverageMoves,
    required this.sensibleWorstMoves,
    required this.carefulOptimalRate,
    required this.carefulFailureRate,
    required this.carefulStuckRate,
    required this.strategistOptimalRate,
    required this.strategistFailureRate,
    required this.strategistAverageMoves,
  });

  /// Average moves wasted by a sensible run; 0 means the board plays itself.
  double get wasteMargin => sensibleAverageMoves - minimumMoves;
}

enum _Player { careless, sensible, careful, strategist }

abstract final class LevelDifficulty {
  /// Deterministic for a given [seed] so tests and the generator agree.
  static DifficultyReport measure(
    LevelData level, {
    int samples = 300,
    int seed = 20260916,
    int? minimumMoves,
  }) {
    final board = BoardEngine(level);
    final optimum =
        minimumMoves ?? LevelSolver.analyzeBoard(board).minimumMoves!;
    final limit = level.moveLimit ?? optimum + 2;

    _Playouts play(_Player player, int salt) =>
        _play(board, optimum, limit, samples, seed ^ salt, player);

    final careless = play(_Player.careless, 0);
    final sensible = play(_Player.sensible, 0x5bd1);
    final careful = board.stoneCount == 0
        ? sensible
        : play(_Player.careful, 0x2c9f);
    final strategist = play(_Player.strategist, 0x71e3);

    return DifficultyReport(
      minimumMoves: optimum,
      moveLimit: limit,
      carelessOptimalRate: careless.optimalRate,
      carelessFailureRate: careless.failureRate,
      sensibleOptimalRate: sensible.optimalRate,
      sensibleFailureRate: sensible.failureRate,
      sensibleStuckRate: sensible.stuckRate,
      sensibleAverageMoves: sensible.averageMoves,
      sensibleWorstMoves: sensible.worstMoves,
      carefulOptimalRate: careful.optimalRate,
      carefulFailureRate: careful.failureRate,
      carefulStuckRate: careful.stuckRate,
      strategistOptimalRate: strategist.optimalRate,
      strategistFailureRate: strategist.failureRate,
      strategistAverageMoves: strategist.averageMoves,
    );
  }

  static _Playouts _play(
    BoardEngine board,
    int optimum,
    int limit,
    int samples,
    int seed,
    _Player player,
  ) {
    final random = Random(seed);
    final buffer = List<int>.filled(board.arrowCount, 0);
    final cap = optimum * 4 + 16;
    var optimal = 0;
    var failures = 0;
    var stuck = 0;
    var total = 0;
    var worst = 0;

    for (var run = 0; run < samples; run++) {
      var key = board.allMask;
      var moves = 0;

      while (key & board.allMask != 0 && moves < cap) {
        if (player == _Player.strategist) {
          final next = _strategistMove(board, key, buffer, random);
          if (next < 0) break;
          moves++;
          key = next;
          continue;
        }

        final alive = key & board.allMask;
        final aux = key >> board.arrowCount;
        var count = player == _Player.careless
            ? 0
            : board.collectExitable(alive, aux, buffer);
        if (player == _Player.careful && count > 0) {
          count = _dropTraps(board, key, buffer, count);
        }
        if (count == 0) {
          count = board.collectPlayable(alive, aux, buffer);
          if (player == _Player.careful && count > 0) {
            count = _dropTraps(board, key, buffer, count);
          }
        }
        if (count == 0) break;

        moves++;
        key = board.move(buffer[random.nextInt(count)], key);
      }

      final finished = key & board.allMask == 0;
      if (finished && moves == optimum) optimal++;
      if (!finished) stuck++;
      if (!finished || moves > limit) failures++;
      total += moves;
      if (moves > worst) worst = moves;
    }

    return _Playouts(
      optimalRate: optimal / samples,
      failureRate: failures / samples,
      stuckRate: stuck / samples,
      averageMoves: total / samples,
      worstMoves: worst,
    );
  }

  /// One move of the worked-out strategy, or -1 when it is stuck. The order
  /// of the classes is the whole strategy: leave first, then a harmless slide,
  /// then wait for the Gears, and only turn a Rotator as a last resort.
  static int _strategistMove(
    BoardEngine board,
    int key,
    List<int> buffer,
    Random random,
  ) {
    final alive = key & board.allMask;
    final aux = key >> board.arrowCount;
    final exits = <int>[];
    final slides = <int>[];
    final turns = <int>[];
    final count = board.collectPlayable(alive, aux, buffer);
    for (var i = 0; i < count; i++) {
      final arrow = buffer[i];
      if (board.typeOf(arrow) == ArrowType.stone) {
        if (!board.slideBlocksSomeone(arrow, key)) slides.add(arrow);
      } else if (board.canExit(arrow, alive, aux)) {
        exits.add(arrow);
      } else {
        turns.add(arrow);
      }
    }

    if (exits.isNotEmpty) {
      return board.move(exits[random.nextInt(exits.length)], key);
    }
    if (slides.isNotEmpty) {
      return board.move(slides[random.nextInt(slides.length)], key);
    }
    final waited = board.waitMove(key);
    if (waited >= 0) return waited;
    if (turns.isNotEmpty) {
      return board.move(turns[random.nextInt(turns.length)], key);
    }
    return -1;
  }

  /// Removes Stone slides that visibly block someone, keeping the list
  /// unchanged when that would leave nothing to play.
  static int _dropTraps(
    BoardEngine board,
    int key,
    List<int> moves,
    int count,
  ) {
    var kept = 0;
    for (var i = 0; i < count; i++) {
      final arrow = moves[i];
      final risky =
          board.typeOf(arrow) == ArrowType.stone &&
          board.slideBlocksSomeone(arrow, key);
      if (!risky) moves[kept++] = arrow;
    }
    return kept == 0 ? count : kept;
  }
}

class _Playouts {
  final double optimalRate;
  final double failureRate;
  final double stuckRate;
  final double averageMoves;
  final int worstMoves;

  const _Playouts({
    required this.optimalRate,
    required this.failureRate,
    required this.stuckRate,
    required this.averageMoves,
    required this.worstMoves,
  });
}
