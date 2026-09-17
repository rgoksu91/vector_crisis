import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/game/logic/board_engine.dart';
import 'package:vector_crisis/game/logic/level_solver.dart';
import 'package:vector_crisis/game/models/arrow_direction.dart';
import 'package:vector_crisis/game/models/arrow_seed.dart';
import 'package:vector_crisis/game/models/level_data.dart';

// Row 1 holds a Stone sliding right towards A. B, above the lane, needs the
// cell the Stone lands on if it is slid first.
//
//   . . . B .
//   S . . . A
//   . . . . .
const _trap = LevelData(
  id: 1,
  rows: 3,
  columns: 5,
  arrows: [
    ArrowSeed.stone(1, 0, ArrowDirection.right),
    ArrowSeed.normal(1, 4, ArrowDirection.right),
    ArrowSeed.normal(0, 3, ArrowDirection.down),
  ],
);

void main() {
  test('a stone slides to the first obstacle and stays as a wall', () {
    final board = BoardEngine(_trap);
    expect(board.slideSteps(0, board.allMask, 0), 3);

    final next = board.move(0, board.allMask);
    expect(next & board.allMask, board.allMask & ~1);
    // B's ray now runs into the wall at (1, 3).
    expect(board.isClear(2, next & board.allMask, next >> 3), isFalse);
    // A is untouched by the wall behind it.
    expect(board.isClear(1, next & board.allMask, next >> 3), isTrue);
  });

  test('sliding the stone too early jams the board', () {
    final solution = LevelSolver.findSolution(_trap)!;
    expect(solution, hasLength(3));
    final stoneStep = solution.indexWhere((action) => action.arrowId == 0);
    final bStep = solution.indexWhere((action) => action.arrowId == 2);
    expect(bStep, lessThan(stoneStep));
    expect(solution[stoneStep].type, SolverActionType.slide);

    const jammed = LevelData(
      id: 1,
      rows: 3,
      columns: 5,
      walls: [(row: 1, column: 3)],
      arrows: [
        ArrowSeed.normal(1, 4, ArrowDirection.right),
        ArrowSeed.normal(0, 3, ArrowDirection.down),
      ],
    );
    final analysis = LevelSolver.analyze(jammed);
    expect(analysis.isSolvable, isFalse);
    expect(analysis.hitStateLimit, isFalse);
  });

  test('a stone with nothing ahead slides to the edge', () {
    const level = LevelData(
      id: 1,
      rows: 1,
      columns: 4,
      arrows: [ArrowSeed.stone(0, 0, ArrowDirection.right)],
    );
    final board = BoardEngine(level);
    expect(board.slideSteps(0, 1, 0), 3);
    expect(board.canExit(0, 1, 0), isTrue);
    expect(LevelSolver.findSolution(level), hasLength(1));
  });

  test('a stone against an obstacle cannot move', () {
    const level = LevelData(
      id: 1,
      rows: 1,
      columns: 3,
      arrows: [
        ArrowSeed.stone(0, 0, ArrowDirection.right),
        ArrowSeed.normal(0, 1, ArrowDirection.up),
      ],
    );
    final board = BoardEngine(level);
    expect(board.move(0, board.allMask), -1);
    expect(board.isPlayable(0, board.allMask, 0), isFalse);
  });

  test('a landed stone stops a later stone short', () {
    const level = LevelData(
      id: 1,
      rows: 3,
      columns: 4,
      arrows: [
        ArrowSeed.stone(0, 2, ArrowDirection.down),
        ArrowSeed.stone(2, 0, ArrowDirection.right),
      ],
    );
    final board = BoardEngine(level);
    final afterFirst = board.move(0, board.allMask);
    // The first Stone lands on (2, 2), so the second one stops at (2, 1).
    expect(board.slideSteps(1, afterFirst & board.allMask, afterFirst >> 2), 1);
  });

  test('bombs cannot blast a stone', () {
    const level = LevelData(
      id: 1,
      rows: 1,
      columns: 3,
      arrows: [
        ArrowSeed.bomb(0, 1, ArrowDirection.up),
        ArrowSeed.stone(0, 0, ArrowDirection.left),
        ArrowSeed.normal(0, 2, ArrowDirection.right),
      ],
    );
    final board = BoardEngine(level);
    final next = board.move(0, board.allMask);
    expect(next & board.allMask, 1 << 1);
  });

  test('a landed stone in front of an arrow stops a slide at the wall', () {
    const level = LevelData(
      id: 1,
      rows: 3,
      columns: 5,
      arrows: [
        ArrowSeed.stone(0, 1, ArrowDirection.down),
        ArrowSeed.stone(2, 0, ArrowDirection.right),
        ArrowSeed.normal(2, 3, ArrowDirection.up),
      ],
    );
    final board = BoardEngine(level);
    // The first Stone lands on (2, 1), right in front of the second one,
    // which must now stay put even though its first arrow is further along.
    final afterFirst = board.move(0, board.allMask);
    expect(board.slideSteps(1, afterFirst & board.allMask, afterFirst >> 3), 0);
  });
}
