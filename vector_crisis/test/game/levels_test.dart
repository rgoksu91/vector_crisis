import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/game/data/levels.dart';
import 'package:vector_crisis/game/logic/board_rules.dart';
import 'package:vector_crisis/game/logic/level_difficulty.dart';
import 'package:vector_crisis/game/logic/level_solver.dart';
import 'package:vector_crisis/game/models/arrow_direction.dart';
import 'package:vector_crisis/game/models/arrow_seed.dart';
import 'package:vector_crisis/game/models/arrow_type.dart';
import 'package:vector_crisis/game/models/level_data.dart';

void main() {
  final analyses = {
    for (final level in levels) level.id: LevelSolver.analyze(level),
  };

  test('the level catalog is structurally valid', () {
    expect(levels, hasLength(300));

    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];
      expect(level.id, index + 1, reason: 'Level IDs must be sequential.');
      expect(level.rows, inInclusiveRange(3, 8));
      expect(level.columns, inInclusiveRange(3, 8));
      expect(level.arrows, isNotEmpty);

      final cells = <BoardCell>{};
      for (final arrow in level.arrows) {
        expect(
          BoardRules.isInside(
            arrow.row,
            arrow.column,
            level.rows,
            level.columns,
          ),
          isTrue,
          reason: 'Level ${level.id} contains an out-of-bounds arrow.',
        );
        expect(
          cells.add((row: arrow.row, column: arrow.column)),
          isTrue,
          reason: 'Level ${level.id} contains overlapping arrows.',
        );
      }
    }
  });

  test('the tutorial levels keep their original layouts', () {
    expect(_fingerprint(levels.take(3)), _tutorialFingerprint);
  });

  test('every level from 4 on is scored against the solver optimum', () {
    for (final level in levels.skip(3)) {
      final analysis = analyses[level.id]!;
      expect(analysis.hitStateLimit, isFalse, reason: 'Level ${level.id}');
      expect(
        level.targetMoves,
        analysis.minimumMoves,
        reason: 'Level ${level.id} target is not the solver optimum.',
      );
      expect(level.moveLimit, greaterThan(level.targetMoves!));
      expect(
        level.twoStarMoves,
        inInclusiveRange(level.targetMoves! + 1, level.moveLimit!),
      );
    }
  });

  test('the campaign never gets shorter from one level to the next', () {
    for (var index = 4; index < levels.length; index++) {
      expect(
        levels[index].targetMoves,
        greaterThanOrEqualTo(levels[index - 1].targetMoves!),
        reason: 'Level ${levels[index].id} is easier than the one before it.',
      );
    }
    expect(levels.last.targetMoves, greaterThanOrEqualTo(30));
  });

  test('every generated level opens with a real choice', () {
    for (final level in levels.skip(3)) {
      final maxOpenings = switch (level.rows) {
        <= 6 => 4,
        7 => 5,
        _ => 6,
      };
      expect(
        analyses[level.id]!.initialExitOptions,
        inInclusiveRange(2, maxOpenings),
        reason: 'Level ${level.id}',
      );
    }
  });

  test('mechanics arrive on the schedule the hints announce', () {
    bool has(LevelData level, ArrowType type) =>
        level.arrows.any((arrow) => arrow.type == type);

    for (final level in levels.skip(5)) {
      expect(has(level, ArrowType.rotator), isTrue, reason: '${level.id}');
    }
    for (final level in levels.skip(7)) {
      expect(has(level, ArrowType.frozen), isTrue, reason: '${level.id}');
    }
    for (final level in levels.skip(9)) {
      expect(has(level, ArrowType.bomb), isTrue, reason: '${level.id}');
    }
    for (final level in levels.take(11)) {
      expect(has(level, ArrowType.stone), isFalse, reason: '${level.id}');
    }
    for (final level in levels.skip(11)) {
      expect(has(level, ArrowType.stone), isTrue, reason: '${level.id}');
    }
    for (final level in levels.skip(5).take(4)) {
      expect(
        analyses[level.id]!.solution!.any(
          (action) => action.type == SolverActionType.rotateClockwise,
        ),
        isTrue,
        reason: 'Level ${level.id} never needs its Rotator turned.',
      );
    }
  });

  // The shipped catalog before the rebuild handed three stars to unplanned
  // play on three levels out of four. This keeps that from coming back.
  test('from level 10 on, unplanned play is punished', () {
    for (final level in levels.skip(9)) {
      final report = LevelDifficulty.measure(
        level,
        samples: 240,
        minimumMoves: level.targetMoves,
      );
      expect(
        report.sensibleOptimalRate,
        lessThanOrEqualTo(0.55),
        reason: 'Level ${level.id} gives three stars without planning.',
      );
      expect(
        report.sensibleFailureRate,
        greaterThanOrEqualTo(0.05),
        reason: 'Level ${level.id} cannot be lost without planning.',
      );
      if (level.id < 12) continue;
      expect(
        report.sensibleStuckRate,
        greaterThanOrEqualTo(0.15),
        reason: 'Level ${level.id} has a Stone that never jams the board.',
      );
      expect(
        report.carefulFailureRate,
        greaterThanOrEqualTo(0.08),
        reason: 'Level ${level.id} falls to one move of lookahead.',
      );
    }
  });

  test('the complete catalog has no exact duplicate boards', () {
    final signatures = <String>{};
    for (final level in levels) {
      expect(
        signatures.add(_levelSignature(level)),
        isTrue,
        reason: 'Level ${level.id} is an exact duplicate.',
      );
    }
  });

  test('every shipped level has a gameplay-valid solution', () {
    for (final level in levels) {
      final solution = LevelSolver.findSolution(level);
      expect(solution, isNotNull, reason: 'Level ${level.id} is unsolvable.');

      final simulation = _GameplaySimulation(level);
      for (final action in solution!) {
        simulation.apply(action);
      }
      expect(
        simulation.arrows,
        isEmpty,
        reason: 'Solver plan did not clear level ${level.id}.',
      );
    }
  });

  test('a blocked rotator rotates clockwise instead of exiting', () {
    const level = LevelData(
      id: 1,
      rows: 3,
      columns: 3,
      arrows: [
        ArrowSeed(
          row: 1,
          column: 1,
          direction: ArrowDirection.right,
          type: ArrowType.rotator,
        ),
        ArrowSeed(row: 1, column: 2, direction: ArrowDirection.right),
      ],
    );
    final simulation = _GameplaySimulation(level);

    simulation.apply(
      const SolverAction(arrowId: 0, type: SolverActionType.rotateClockwise),
    );

    expect(
      simulation.arrows.singleWhere((arrow) => arrow.id == 0).direction,
      ArrowDirection.down,
    );
    expect(simulation.arrows, hasLength(2));
  });

  test('removing an orthogonal neighbour thaws a frozen arrow', () {
    const level = LevelData(
      id: 1,
      rows: 3,
      columns: 3,
      arrows: [
        ArrowSeed(
          row: 1,
          column: 1,
          direction: ArrowDirection.up,
          type: ArrowType.frozen,
        ),
        ArrowSeed(row: 1, column: 2, direction: ArrowDirection.right),
      ],
    );
    final simulation = _GameplaySimulation(level);

    simulation.apply(
      const SolverAction(arrowId: 1, type: SolverActionType.exit),
    );

    expect(simulation.arrows.single.frozen, isFalse);
  });

  test('a bomb removes only its orthogonal neighbours', () {
    const level = LevelData(
      id: 1,
      rows: 4,
      columns: 4,
      arrows: [
        ArrowSeed(
          row: 1,
          column: 3,
          direction: ArrowDirection.right,
          type: ArrowType.bomb,
        ),
        ArrowSeed(row: 0, column: 3, direction: ArrowDirection.up),
        ArrowSeed(row: 2, column: 3, direction: ArrowDirection.down),
        ArrowSeed(row: 1, column: 2, direction: ArrowDirection.left),
        ArrowSeed(row: 0, column: 2, direction: ArrowDirection.left),
      ],
    );
    final simulation = _GameplaySimulation(level);

    simulation.apply(
      const SolverAction(arrowId: 0, type: SolverActionType.exit),
    );

    expect(simulation.arrows.map((arrow) => arrow.id), [4]);
  });

  test('a bomb removed by another bomb does not chain-trigger', () {
    const level = LevelData(
      id: 1,
      rows: 4,
      columns: 4,
      arrows: [
        ArrowSeed(
          row: 1,
          column: 3,
          direction: ArrowDirection.right,
          type: ArrowType.bomb,
        ),
        ArrowSeed(
          row: 2,
          column: 3,
          direction: ArrowDirection.down,
          type: ArrowType.bomb,
        ),
        ArrowSeed(row: 3, column: 3, direction: ArrowDirection.down),
      ],
    );
    final simulation = _GameplaySimulation(level);

    simulation.apply(
      const SolverAction(arrowId: 0, type: SolverActionType.exit),
    );

    expect(simulation.arrows.map((arrow) => arrow.id), [2]);
  });
}

const _tutorialFingerprint = 1018013165;

int _fingerprint(Iterable<LevelData> levels) {
  var fingerprint = 17;
  for (final level in levels) {
    fingerprint = _mix(fingerprint, level.id);
    fingerprint = _mix(fingerprint, level.rows);
    fingerprint = _mix(fingerprint, level.columns);
    for (final arrow in level.arrows) {
      fingerprint = _mix(fingerprint, arrow.row);
      fingerprint = _mix(fingerprint, arrow.column);
      fingerprint = _mix(fingerprint, arrow.direction.index);
      fingerprint = _mix(fingerprint, arrow.type.index);
    }
  }
  return fingerprint;
}

int _mix(int value, int part) => (value * 31 + part) & 0x7fffffff;

String _levelSignature(LevelData level) {
  final arrows =
      level.arrows
          .map(
            (arrow) =>
                '${arrow.row}:${arrow.column}:${arrow.direction.name}:'
                '${arrow.type.name}',
          )
          .toList()
        ..sort();
  return '${level.rows}x${level.columns}|${arrows.join('|')}';
}

class _GameplaySimulation {
  final int rows;
  final int columns;
  final List<_GameplayArrow> arrows;
  final Set<BoardCell> walls;

  _GameplaySimulation(LevelData level)
    : rows = level.rows,
      columns = level.columns,
      walls = level.walls.toSet(),
      arrows = [
        for (var index = 0; index < level.arrows.length; index++)
          _GameplayArrow.fromSeed(index, level.arrows[index]),
      ];

  void apply(SolverAction action) {
    final arrow = arrows.singleWhere((arrow) => arrow.id == action.arrowId);
    expect(arrow.frozen, isFalse, reason: 'A frozen arrow was selected.');

    final clear = BoardRules.isPathClear(
      row: arrow.row,
      column: arrow.column,
      direction: arrow.direction,
      rows: rows,
      columns: columns,
      occupiedCells: _occupied(),
    );

    if (action.type == SolverActionType.slide) {
      expect(arrow.type, ArrowType.stone);
      final occupied = _occupied().toSet();
      var row = arrow.row;
      var column = arrow.column;
      while (true) {
        final nextRow = row + arrow.direction.rowDelta;
        final nextColumn = column + arrow.direction.columnDelta;
        if (!BoardRules.isInside(nextRow, nextColumn, rows, columns) ||
            occupied.contains((row: nextRow, column: nextColumn))) {
          break;
        }
        row = nextRow;
        column = nextColumn;
      }
      expect(
        (row, column),
        isNot((arrow.row, arrow.column)),
        reason: 'A Stone with no room was slid.',
      );
      walls.add((row: row, column: column));
      _remove({(row: arrow.row, column: arrow.column)});
      return;
    }
    expect(arrow.type, isNot(ArrowType.stone));

    if (action.type == SolverActionType.rotateClockwise) {
      expect(arrow.type, ArrowType.rotator);
      expect(clear, isFalse, reason: 'A clear rotator must exit, not rotate.');
      arrow.direction = arrow.direction.clockwise;
      return;
    }

    expect(clear, isTrue, reason: 'An arrow exited through a blocked path.');
    final removed = <BoardCell>{(row: arrow.row, column: arrow.column)};
    if (arrow.type == ArrowType.bomb) {
      for (final other in arrows) {
        if (other.type != ArrowType.stone &&
            BoardRules.areAdjacent(
              arrow.row,
              arrow.column,
              other.row,
              other.column,
            )) {
          removed.add((row: other.row, column: other.column));
        }
      }
    }

    _remove(removed);
  }

  Iterable<BoardCell> _occupied() => arrows
      .map<BoardCell>((arrow) => (row: arrow.row, column: arrow.column))
      .followedBy(walls);

  void _remove(Set<BoardCell> removed) {
    arrows.removeWhere(
      (arrow) => removed.contains((row: arrow.row, column: arrow.column)),
    );
    for (final remaining in arrows.where((arrow) => arrow.frozen)) {
      if (removed.any(
        (cell) => BoardRules.areAdjacent(
          remaining.row,
          remaining.column,
          cell.row,
          cell.column,
        ),
      )) {
        remaining.frozen = false;
      }
    }
  }
}

class _GameplayArrow {
  final int id;
  final int row;
  final int column;
  final ArrowType type;
  ArrowDirection direction;
  bool frozen;

  _GameplayArrow.fromSeed(this.id, ArrowSeed seed)
    : row = seed.row,
      column = seed.column,
      type = seed.type,
      direction = seed.direction,
      frozen = seed.type == ArrowType.frozen;
}
