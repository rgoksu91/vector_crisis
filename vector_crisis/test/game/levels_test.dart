import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/game/data/levels.dart';
import 'package:vector_crisis/game/logic/board_rules.dart';
import 'package:vector_crisis/game/logic/level_solver.dart';
import 'package:vector_crisis/game/models/arrow_direction.dart';
import 'package:vector_crisis/game/models/arrow_seed.dart';
import 'package:vector_crisis/game/models/arrow_type.dart';
import 'package:vector_crisis/game/models/level_data.dart';

void main() {
  test(
    'Levels 1-9 remain byte-for-byte compatible with the original layouts',
    () {
      expect(_baselineFingerprint(), 1121777089);
    },
  );

  test('Levels 10-20 meet the branching and efficiency difficulty floor', () {
    const expectedMetrics = <int, (int minimumMoves, int initialMoves)>{
      10: (6, 4),
      11: (7, 3),
      12: (10, 2),
      13: (8, 3),
      14: (11, 4),
      15: (12, 4),
      16: (11, 4),
      17: (12, 4),
      18: (13, 4),
      19: (13, 4),
      20: (14, 4),
    };

    for (final level in levels.skip(9).take(11)) {
      final analysis = LevelSolver.analyze(level);
      final expected = expectedMetrics[level.id]!;

      expect(analysis.minimumMoves, expected.$1, reason: 'Level ${level.id}');
      expect(
        analysis.initialPlayableMoves,
        expected.$2,
        reason: 'Level ${level.id}',
      );
      expect(
        analysis.initialPlayableMoves,
        inInclusiveRange(2, 4),
        reason: 'Level ${level.id} should open with meaningful alternatives.',
      );
      expect(
        analysis.decisionStates,
        greaterThanOrEqualTo(3),
        reason: 'Level ${level.id} is too scripted.',
      );
      expect(
        analysis.maxForcedMoveStreak,
        lessThanOrEqualTo(3),
        reason: 'Level ${level.id} has a long forced-move sequence.',
      );
      expect(
        analysis.playableMovesAlongSolution,
        hasLength(analysis.minimumMoves!),
      );
    }

    for (final level in levels.skip(15).take(5)) {
      expect(
        LevelSolver.analyze(level).minimumMoves,
        inInclusiveRange(11, 16),
        reason: 'Level ${level.id} misses the 45-90 second depth proxy.',
      );
    }
  });

  test('Levels 10-100 reject long scripted solution corridors', () {
    for (final level in levels.skip(9)) {
      final analysis = LevelSolver.analyze(level);
      expect(
        analysis.decisionStates,
        greaterThanOrEqualTo(2),
        reason: 'Level ${level.id} has fewer than two decision states.',
      );
      expect(
        analysis.maxForcedMoveStreak,
        lessThanOrEqualTo(4),
        reason: 'Level ${level.id} stays forced for too long.',
      );
    }
  });

  test('the level catalog is structurally valid', () {
    expect(levels, hasLength(100));

    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];
      expect(level.id, index + 1, reason: 'Level IDs must be sequential.');
      expect(level.rows, inInclusiveRange(3, 6));
      expect(level.columns, inInclusiveRange(3, 6));
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

  test(
    'every move-limited level can be solved inside its efficiency budget',
    () {
      for (final level in levels.where((level) => level.moveLimit != null)) {
        final minimumMoves = LevelSolver.analyze(level).minimumMoves;
        expect(
          level.targetMoves,
          minimumMoves,
          reason: 'Level ${level.id} target is not the solver optimum.',
        );
        expect(
          minimumMoves,
          lessThanOrEqualTo(level.moveLimit!),
          reason: 'Level ${level.id} cannot fit its move budget.',
        );
      }
    },
  );

  test('the Rotator arc follows its design constraints', () {
    final signatures = <String>{};

    for (final level in levels.skip(15).take(10)) {
      final analysis = LevelSolver.analyze(level);
      final rotators = level.arrows
          .where((arrow) => arrow.type == ArrowType.rotator)
          .length;
      final normals = level.arrows
          .where((arrow) => arrow.type == ArrowType.normal)
          .length;
      final signature = _levelSignature(level);

      expect(level.id, inInclusiveRange(16, 25));
      expect(level.difficulty, inInclusiveRange(2, 6));
      expect(level.targetMoves, isNotNull);
      expect(rotators, inInclusiveRange(1, 4));
      expect(normals / level.arrows.length, greaterThanOrEqualTo(0.6));
      expect(
        level.arrows.every(
          (arrow) =>
              arrow.type == ArrowType.normal || arrow.type == ArrowType.rotator,
        ),
        isTrue,
      );
      expect(analysis.isSolvable, isTrue);
      expect(analysis.hitStateLimit, isFalse);
      expect(analysis.initialPlayableMoves, inInclusiveRange(1, 6));
      expect(
        analysis.solution!.any(
          (action) => action.type == SolverActionType.rotateClockwise,
        ),
        isTrue,
        reason: 'Level ${level.id} does not require its Rotator mechanic.',
      );
      expect(
        (analysis.minimumMoves! - level.targetMoves!).abs(),
        lessThanOrEqualTo(2),
        reason: 'Level ${level.id} targetMoves is not calibrated.',
      );
      expect(
        signatures.add(signature),
        isTrue,
        reason: 'Level ${level.id} duplicates an earlier Rotator board.',
      );
    }
  });

  test('the Frozen arc follows its design constraints', () {
    final signatures = <String>{};

    for (final level in levels.skip(25).take(10)) {
      final analysis = LevelSolver.analyze(level);
      final frozen = level.arrows
          .where((arrow) => arrow.type == ArrowType.frozen)
          .length;
      final normals = level.arrows
          .where((arrow) => arrow.type == ArrowType.normal)
          .length;

      expect(level.id, inInclusiveRange(26, 35));
      expect(level.difficulty, inInclusiveRange(2, 5));
      expect(level.targetMoves, isNotNull);
      expect(frozen, inInclusiveRange(1, 4));
      expect(normals / level.arrows.length, greaterThanOrEqualTo(0.6));
      expect(
        level.arrows.any((arrow) => arrow.type == ArrowType.bomb),
        isFalse,
      );
      expect(analysis.isSolvable, isTrue);
      expect(analysis.hitStateLimit, isFalse);
      expect(analysis.initialPlayableMoves, inInclusiveRange(1, 7));
      expect(
        (analysis.minimumMoves! - level.targetMoves!).abs(),
        lessThanOrEqualTo(2),
        reason: 'Level ${level.id} targetMoves is not calibrated.',
      );
      expect(
        signatures.add(_levelSignature(level)),
        isTrue,
        reason: 'Level ${level.id} duplicates an earlier Frozen board.',
      );
    }
  });

  test('the Bomb arc follows its design constraints', () {
    final signatures = <String>{};

    for (final level in levels.skip(35).take(10)) {
      final analysis = LevelSolver.analyze(level);
      final bombs = level.arrows
          .where((arrow) => arrow.type == ArrowType.bomb)
          .length;
      final normals = level.arrows
          .where((arrow) => arrow.type == ArrowType.normal)
          .length;

      expect(level.id, inInclusiveRange(36, 45));
      expect(level.difficulty, inInclusiveRange(2, 5));
      expect(level.targetMoves, isNotNull);
      expect(bombs, inInclusiveRange(1, 3));
      expect(normals / level.arrows.length, greaterThanOrEqualTo(0.6));
      expect(analysis.isSolvable, isTrue);
      expect(analysis.hitStateLimit, isFalse);
      expect(analysis.initialPlayableMoves, inInclusiveRange(1, 9));
      expect(
        analysis.solution!.any(
          (action) => level.arrows[action.arrowId].type == ArrowType.bomb,
        ),
        isTrue,
        reason: 'Level ${level.id} does not use its Bomb mechanic.',
      );
      expect(
        (analysis.minimumMoves! - level.targetMoves!).abs(),
        lessThanOrEqualTo(2),
        reason: 'Level ${level.id} targetMoves is not calibrated.',
      );
      expect(
        signatures.add(_levelSignature(level)),
        isTrue,
        reason: 'Level ${level.id} duplicates an earlier Bomb board.',
      );
    }
  });

  test('the Mixed arc follows its design constraints', () {
    final signatures = <String>{};

    for (final level in levels.skip(45).take(15)) {
      final analysis = LevelSolver.analyze(level);
      final specials = level.arrows
          .where((arrow) => arrow.type != ArrowType.normal)
          .length;
      final rotators = level.arrows
          .where((arrow) => arrow.type == ArrowType.rotator)
          .length;
      final bombs = level.arrows
          .where((arrow) => arrow.type == ArrowType.bomb)
          .length;

      expect(level.id, inInclusiveRange(46, 60));
      expect(level.difficulty, inInclusiveRange(4, 7));
      expect(level.targetMoves, isNotNull);
      expect(rotators, lessThanOrEqualTo(4));
      expect(bombs, lessThanOrEqualTo(3));
      expect(1 - specials / level.arrows.length, greaterThanOrEqualTo(0.6));
      expect(analysis.isSolvable, isTrue);
      expect(analysis.hitStateLimit, isFalse);
      expect(analysis.initialPlayableMoves, inInclusiveRange(1, 9));
      expect(
        (analysis.minimumMoves! - level.targetMoves!).abs(),
        lessThanOrEqualTo(3),
        reason: 'Level ${level.id} targetMoves is not calibrated.',
      );
      expect(
        signatures.add(_levelSignature(level)),
        isTrue,
        reason: 'Level ${level.id} duplicates an earlier Mixed board.',
      );
    }
  });

  test('the Dense arc follows its design constraints', () {
    final signatures = <String>{};

    for (final level in levels.skip(60).take(15)) {
      final analysis = LevelSolver.analyze(level);
      final normals = level.arrows
          .where((arrow) => arrow.type == ArrowType.normal)
          .length;
      final rotators = level.arrows
          .where((arrow) => arrow.type == ArrowType.rotator)
          .length;
      final bombs = level.arrows
          .where((arrow) => arrow.type == ArrowType.bomb)
          .length;

      expect(level.id, inInclusiveRange(61, 75));
      expect(level.rows, 6);
      expect(level.columns, 6);
      expect(level.difficulty, inInclusiveRange(4, 7));
      expect(level.arrows.length, inInclusiveRange(12, 22));
      expect(normals / level.arrows.length, greaterThanOrEqualTo(0.6));
      expect(rotators, lessThanOrEqualTo(4));
      expect(bombs, lessThanOrEqualTo(3));
      expect(analysis.isSolvable, isTrue);
      expect(analysis.hitStateLimit, isFalse);
      expect(analysis.initialPlayableMoves, inInclusiveRange(1, 9));
      expect(
        (analysis.minimumMoves! - level.targetMoves!).abs(),
        lessThanOrEqualTo(2),
        reason: 'Level ${level.id} targetMoves is not calibrated.',
      );
      expect(
        signatures.add(_levelSignature(level)),
        isTrue,
        reason: 'Level ${level.id} duplicates an earlier Dense board.',
      );
    }
  });

  test('the Advanced arc follows its design constraints', () {
    final signatures = <String>{};

    for (final level in levels.skip(75).take(15)) {
      final analysis = LevelSolver.analyze(level);
      final normals = level.arrows
          .where((arrow) => arrow.type == ArrowType.normal)
          .length;
      final rotators = level.arrows
          .where((arrow) => arrow.type == ArrowType.rotator)
          .length;
      final bombs = level.arrows
          .where((arrow) => arrow.type == ArrowType.bomb)
          .length;

      expect(level.id, inInclusiveRange(76, 90));
      expect(level.rows, 6);
      expect(level.columns, 6);
      expect(level.difficulty, inInclusiveRange(4, 8));
      expect(level.arrows.length, inInclusiveRange(12, 24));
      expect(normals / level.arrows.length, greaterThanOrEqualTo(0.6));
      expect(rotators, lessThanOrEqualTo(4));
      expect(bombs, lessThanOrEqualTo(3));
      expect(analysis.isSolvable, isTrue);
      expect(analysis.hitStateLimit, isFalse);
      expect(analysis.initialPlayableMoves, inInclusiveRange(1, 11));
      expect(
        (analysis.minimumMoves! - level.targetMoves!).abs(),
        lessThanOrEqualTo(2),
        reason: 'Level ${level.id} targetMoves is not calibrated.',
      );
      expect(
        signatures.add(_levelSignature(level)),
        isTrue,
        reason: 'Level ${level.id} duplicates an earlier Advanced board.',
      );
    }
  });

  test('the Mastery arc follows its design constraints', () {
    final signatures = <String>{};

    for (final level in levels.skip(90).take(10)) {
      final analysis = LevelSolver.analyze(level);
      final normals = level.arrows
          .where((arrow) => arrow.type == ArrowType.normal)
          .length;
      final rotators = level.arrows
          .where((arrow) => arrow.type == ArrowType.rotator)
          .length;
      final frozen = level.arrows
          .where((arrow) => arrow.type == ArrowType.frozen)
          .length;
      final bombs = level.arrows
          .where((arrow) => arrow.type == ArrowType.bomb)
          .length;

      expect(level.id, inInclusiveRange(91, 100));
      expect(level.rows, 6);
      expect(level.columns, 6);
      expect(level.difficulty, inInclusiveRange(5, 8));
      expect(normals / level.arrows.length, greaterThanOrEqualTo(0.6));
      expect(rotators, lessThanOrEqualTo(4));
      expect(frozen, lessThanOrEqualTo(4));
      expect(bombs, lessThanOrEqualTo(3));
      expect(analysis.isSolvable, isTrue);
      expect(analysis.hitStateLimit, isFalse);
      expect(analysis.initialPlayableMoves, inInclusiveRange(1, 9));
      expect(
        (analysis.minimumMoves! - level.targetMoves!).abs(),
        lessThanOrEqualTo(2),
        reason: 'Level ${level.id} targetMoves is not calibrated.',
      );
      expect(
        signatures.add(_levelSignature(level)),
        isTrue,
        reason: 'Level ${level.id} duplicates an earlier Mastery board.',
      );
    }

    final finalLevel = levels.last;
    expect(finalLevel.arrows.length, inInclusiveRange(20, 26));
    expect(
      finalLevel.arrows
          .where((arrow) => arrow.type == ArrowType.rotator)
          .length,
      inInclusiveRange(2, 4),
    );
    expect(
      finalLevel.arrows.where((arrow) => arrow.type == ArrowType.frozen).length,
      inInclusiveRange(2, 4),
    );
    expect(
      finalLevel.arrows.where((arrow) => arrow.type == ArrowType.bomb).length,
      inInclusiveRange(1, 3),
    );
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

int _baselineFingerprint() {
  var fingerprint = 17;
  for (final level in levels.take(9)) {
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

  _GameplaySimulation(LevelData level)
    : rows = level.rows,
      columns = level.columns,
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
      occupiedCells: arrows.map(
        (arrow) => (row: arrow.row, column: arrow.column),
      ),
    );

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
        if (BoardRules.areAdjacent(
          arrow.row,
          arrow.column,
          other.row,
          other.column,
        )) {
          removed.add((row: other.row, column: other.column));
        }
      }
    }

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
