import 'dart:collection';

import 'board_engine.dart';
import '../models/arrow_type.dart';
import '../models/level_data.dart';

/// A Stone's tap is a [slide]: it ends as a wall rather than leaving.
enum SolverActionType { rotateClockwise, exit, slide }

class SolverAction {
  final int arrowId;
  final SolverActionType type;

  const SolverAction({required this.arrowId, required this.type});
}

class SolverAnalysis {
  final List<SolverAction>? solution;
  final int initialPlayableMoves;

  /// Arrows that can actually leave the board on move one. A blocked Rotator
  /// counts as playable but not as an opening, because turning it is a choice
  /// about spending a move rather than a way forward.
  final int initialExitOptions;
  final List<int> playableMovesAlongSolution;
  final int visitedStates;
  final bool hitStateLimit;

  const SolverAnalysis({
    required this.solution,
    required this.initialPlayableMoves,
    required this.initialExitOptions,
    required this.playableMovesAlongSolution,
    required this.visitedStates,
    required this.hitStateLimit,
  });

  bool get isSolvable => solution != null;
  int? get minimumMoves => solution?.length;
  int get decisionStates =>
      playableMovesAlongSolution.where((count) => count >= 2).length;
  int get maxForcedMoveStreak {
    var maximum = 0;
    var current = 0;
    for (final count in playableMovesAlongSolution) {
      if (count == 1) {
        current++;
        if (current > maximum) maximum = current;
      } else {
        current = 0;
      }
    }
    return maximum;
  }
}

/// Shortest sequence of taps that clears a board, if one exists.
class LevelSolver {
  static bool isSolvable(LevelData level, {int maxVisitedStates = 400000}) =>
      analyze(level, maxVisitedStates: maxVisitedStates).isSolvable;

  static List<SolverAction>? findSolution(
    LevelData level, {
    int maxVisitedStates = 400000,
  }) => analyze(level, maxVisitedStates: maxVisitedStates).solution;

  static SolverAnalysis analyze(
    LevelData level, {
    int maxVisitedStates = 400000,
  }) => analyzeBoard(BoardEngine(level), maxVisitedStates: maxVisitedStates);

  static SolverAnalysis analyzeBoard(
    BoardEngine board, {
    int maxVisitedStates = 400000,
  }) {
    final initialPlayable = board.playableCount(board.allMask, 0);
    final initialExits = board.exitableCount(board.allMask, 0);

    SolverAnalysis failure({required bool limited, required int visited}) =>
        SolverAnalysis(
          solution: null,
          initialPlayableMoves: initialPlayable,
          initialExitOptions: initialExits,
          playableMovesAlongSolution: const [],
          visitedStates: visited,
          hitStateLimit: limited,
        );

    if (board.arrowCount == 0) {
      return const SolverAnalysis(
        solution: [],
        initialPlayableMoves: 0,
        initialExitOptions: 0,
        playableMovesAlongSolution: [],
        visitedStates: 1,
        hitStateLimit: false,
      );
    }
    if (board.stateBits > 62) {
      throw ArgumentError(
        'Board needs ${board.stateBits} state bits; the key holds 62.',
      );
    }

    final allMask = board.allMask;
    final rootKey = allMask;
    final parent = HashMap<int, int>()..[rootKey] = -1;
    final via = HashMap<int, int>();
    final cost = HashMap<int, int>()..[rootKey] = 0;

    // A* over the lower bound, taking the deepest node of the cheapest tier
    // first. The bound is consistent, so a board whose natural peeling order
    // is already optimal is solved in roughly as many expansions as it has
    // arrows, instead of enumerating every order that ties with it.
    final tiers = <int, List<int>>{};
    var tier = board.movesLowerBound(allMask);
    tiers[tier] = [rootKey];

    while (true) {
      while (tiers[tier] == null || tiers[tier]!.isEmpty) {
        tiers.remove(tier);
        if (tiers.isEmpty) {
          return failure(limited: false, visited: cost.length);
        }
        tier = tiers.keys.reduce((a, b) => a < b ? a : b);
      }

      final key = tiers[tier]!.removeLast();
      final alive = key & allMask;
      final moves = cost[key]!;

      // Stale entry from a route that was later improved on.
      if (moves + board.movesLowerBound(alive) != tier) continue;

      if (alive == 0) {
        return _reconstruct(
          board,
          key,
          parent,
          via,
          initialPlayable,
          initialExits,
        );
      }

      var remaining = alive;
      while (remaining != 0) {
        final bit = remaining & -remaining;
        remaining ^= bit;
        final index = bit.bitLength - 1;

        final nextKey = board.move(index, key);
        if (nextKey < 0) continue;
        final nextAlive = nextKey & allMask;
        final encoded =
            (index << 2) | _actionCode(board, index, alive, nextAlive);

        final known = cost[nextKey];
        if (known != null && known <= moves + 1) continue;
        if (known == null && cost.length >= maxVisitedStates) {
          return failure(limited: true, visited: cost.length);
        }

        parent[nextKey] = key;
        via[nextKey] = encoded;
        cost[nextKey] = moves + 1;

        final nextTier = moves + 1 + board.movesLowerBound(nextAlive);
        (tiers[nextTier] ??= <int>[]).add(nextKey);
        if (nextTier < tier) tier = nextTier;
      }
    }
  }

  static int _actionCode(
    BoardEngine board,
    int arrow,
    int alive,
    int nextAlive,
  ) {
    if (alive == nextAlive) return SolverActionType.rotateClockwise.index;
    if (board.typeOf(arrow) == ArrowType.stone) {
      return SolverActionType.slide.index;
    }
    return SolverActionType.exit.index;
  }

  static SolverAnalysis _reconstruct(
    BoardEngine board,
    int goalKey,
    Map<int, int> parent,
    Map<int, int> via,
    int initialPlayable,
    int initialExits,
  ) {
    final keys = <int>[];
    for (var key = goalKey; key != -1; key = parent[key]!) {
      keys.add(key);
    }
    final path = keys.reversed.toList(growable: false);

    final actions = <SolverAction>[];
    final playable = <int>[];
    for (var step = 0; step < path.length - 1; step++) {
      final key = path[step];
      playable.add(
        board.playableCount(key & board.allMask, key >> board.arrowCount),
      );
      final encoded = via[path[step + 1]]!;
      actions.add(
        SolverAction(
          arrowId: encoded >> 2,
          type: SolverActionType.values[encoded & 3],
        ),
      );
    }

    return SolverAnalysis(
      solution: actions,
      initialPlayableMoves: initialPlayable,
      initialExitOptions: initialExits,
      playableMovesAlongSolution: playable,
      visitedStates: parent.length,
      hitStateLimit: false,
    );
  }
}
