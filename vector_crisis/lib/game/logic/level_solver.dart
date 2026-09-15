import 'dart:collection';

import 'board_rules.dart';
import '../models/arrow_direction.dart';
import '../models/arrow_type.dart';
import '../models/level_data.dart';

enum SolverActionType { rotateClockwise, exit }

class SolverAction {
  final int arrowId;
  final SolverActionType type;

  const SolverAction({required this.arrowId, required this.type});
}

class SolverAnalysis {
  final List<SolverAction>? solution;
  final int initialPlayableMoves;
  final List<int> playableMovesAlongSolution;
  final int visitedStates;
  final bool hitStateLimit;

  const SolverAnalysis({
    required this.solution,
    required this.initialPlayableMoves,
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

class LevelSolver {
  static bool isSolvable(LevelData level, {int maxVisitedStates = 100000}) =>
      analyze(level, maxVisitedStates: maxVisitedStates).isSolvable;

  static List<SolverAction>? findSolution(
    LevelData level, {
    int maxVisitedStates = 100000,
  }) => analyze(level, maxVisitedStates: maxVisitedStates).solution;

  static SolverAnalysis analyze(
    LevelData level, {
    int maxVisitedStates = 100000,
  }) {
    final initial = <_SimArrow>[
      for (var i = 0; i < level.arrows.length; i++)
        _SimArrow(
          id: i,
          row: level.arrows[i].row,
          column: level.arrows[i].column,
          direction: level.arrows[i].direction,
          type: level.arrows[i].type,
          frozen: level.arrows[i].type == ArrowType.frozen,
        ),
    ];

    final queue = Queue<_SearchNode>()
      ..add(
        _SearchNode(
          state: initial,
          actions: const [],
          playableMovesAlongPath: const [],
        ),
      );
    final visited = <String>{_stateKey(initial)};
    final initialPlayableMoves = initial.where((arrow) {
      if (arrow.frozen) return false;
      final clear = _canExit(arrow, initial, level.rows, level.columns);
      return clear || arrow.type == ArrowType.rotator;
    }).length;

    SolverAnalysis result(
      List<SolverAction>? solution, {
      List<int> playableMovesAlongSolution = const [],
      bool limited = false,
    }) {
      return SolverAnalysis(
        solution: solution,
        initialPlayableMoves: initialPlayableMoves,
        playableMovesAlongSolution: playableMovesAlongSolution,
        visitedStates: visited.length,
        hitStateLimit: limited,
      );
    }

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      final state = node.state;
      if (state.isEmpty) {
        return result(
          node.actions,
          playableMovesAlongSolution: node.playableMovesAlongPath,
        );
      }
      final playableMoves = _playableCount(state, level.rows, level.columns);
      final playableMovesAlongPath = [
        ...node.playableMovesAlongPath,
        playableMoves,
      ];

      for (var i = 0; i < state.length; i++) {
        final arrow = state[i];
        if (arrow.frozen) continue;

        final clear = _canExit(arrow, state, level.rows, level.columns);

        if (arrow.type == ArrowType.rotator && !clear) {
          final next = _cloneState(state);
          next[i] = next[i].copyWith(direction: next[i].direction.clockwise);
          final enqueueResult = _enqueue(
            next,
            [
              ...node.actions,
              SolverAction(
                arrowId: arrow.id,
                type: SolverActionType.rotateClockwise,
              ),
            ],
            playableMovesAlongPath,
            queue,
            visited,
            maxVisitedStates,
          );
          if (enqueueResult == _EnqueueResult.limitExceeded) {
            return SolverAnalysis(
              solution: null,
              initialPlayableMoves: initialPlayableMoves,
              playableMovesAlongSolution: const [],
              visitedStates: visited.length,
              hitStateLimit: true,
            );
          }
          continue;
        }

        if (!clear) continue;

        final removed = <_Cell>{_Cell(arrow.row, arrow.column)};
        if (arrow.type == ArrowType.bomb) {
          for (final other in state) {
            if (_adjacent(arrow.row, arrow.column, other.row, other.column)) {
              removed.add(_Cell(other.row, other.column));
            }
          }
        }

        final next = <_SimArrow>[];
        for (final other in state) {
          if (removed.contains(_Cell(other.row, other.column))) continue;

          var frozen = other.frozen;
          if (frozen &&
              removed.any(
                (cell) =>
                    _adjacent(other.row, other.column, cell.row, cell.column),
              )) {
            frozen = false;
          }
          next.add(other.copyWith(frozen: frozen));
        }

        final actions = [
          ...node.actions,
          SolverAction(arrowId: arrow.id, type: SolverActionType.exit),
        ];
        if (next.isEmpty) {
          return result(
            actions,
            playableMovesAlongSolution: playableMovesAlongPath,
          );
        }
        final enqueueResult = _enqueue(
          next,
          actions,
          playableMovesAlongPath,
          queue,
          visited,
          maxVisitedStates,
        );
        if (enqueueResult == _EnqueueResult.limitExceeded) {
          return SolverAnalysis(
            solution: null,
            initialPlayableMoves: initialPlayableMoves,
            playableMovesAlongSolution: const [],
            visitedStates: visited.length,
            hitStateLimit: true,
          );
        }
      }
    }

    return result(null);
  }

  static _EnqueueResult _enqueue(
    List<_SimArrow> state,
    List<SolverAction> actions,
    List<int> playableMovesAlongPath,
    Queue<_SearchNode> queue,
    Set<String> visited,
    int maxVisitedStates,
  ) {
    final key = _stateKey(state);
    if (!visited.add(key)) return _EnqueueResult.skipped;
    if (visited.length > maxVisitedStates) {
      return _EnqueueResult.limitExceeded;
    }
    queue.add(
      _SearchNode(
        state: state,
        actions: actions,
        playableMovesAlongPath: playableMovesAlongPath,
      ),
    );
    return _EnqueueResult.queued;
  }

  static bool _canExit(
    _SimArrow selected,
    List<_SimArrow> state,
    int rows,
    int columns,
  ) {
    return BoardRules.isPathClear(
      row: selected.row,
      column: selected.column,
      direction: selected.direction,
      rows: rows,
      columns: columns,
      occupiedCells: state.map(
        (arrow) => (row: arrow.row, column: arrow.column),
      ),
    );
  }

  static int _playableCount(List<_SimArrow> state, int rows, int columns) =>
      state.where((arrow) {
        if (arrow.frozen) return false;
        return arrow.type == ArrowType.rotator ||
            _canExit(arrow, state, rows, columns);
      }).length;

  static bool _adjacent(int r1, int c1, int r2, int c2) =>
      BoardRules.areAdjacent(r1, c1, r2, c2);

  static List<_SimArrow> _cloneState(List<_SimArrow> state) =>
      state.map((arrow) => arrow.copyWith()).toList(growable: true);

  static String _stateKey(List<_SimArrow> state) {
    final sorted = [...state]..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map(
          (a) =>
              '${a.id}:${a.row}:${a.column}:${a.direction.name}:'
              '${a.type.name}:${a.frozen ? 1 : 0}',
        )
        .join('|');
  }
}

enum _EnqueueResult { skipped, queued, limitExceeded }

class _SearchNode {
  final List<_SimArrow> state;
  final List<SolverAction> actions;
  final List<int> playableMovesAlongPath;

  const _SearchNode({
    required this.state,
    required this.actions,
    required this.playableMovesAlongPath,
  });
}

class _Cell {
  final int row;
  final int column;

  const _Cell(this.row, this.column);

  @override
  bool operator ==(Object other) =>
      other is _Cell && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}

class _SimArrow {
  final int id;
  final int row;
  final int column;
  final ArrowDirection direction;
  final ArrowType type;
  final bool frozen;

  const _SimArrow({
    required this.id,
    required this.row,
    required this.column,
    required this.direction,
    required this.type,
    required this.frozen,
  });

  _SimArrow copyWith({ArrowDirection? direction, bool? frozen}) {
    return _SimArrow(
      id: id,
      row: row,
      column: column,
      direction: direction ?? this.direction,
      type: type,
      frozen: frozen ?? this.frozen,
    );
  }
}
