// ARCHIVED DRAFT -- kept for reference only, not part of the build.
//
// First attempt at a level generator: random boards filtered by solver
// metrics. Superseded by tool/generate_levels.dart (run through
// tool/generate_campaign.sh). It predates Stones and the 300-level plan,
// and it writes lib/game/data/progression_levels.dart, which nothing uses.

// // ignore_for_file: avoid_print
//
// import 'dart:io';
// import 'dart:math';
//
// import 'package:vector_crisis/game/logic/level_solver.dart';
// import 'package:vector_crisis/game/models/arrow_direction.dart';
// import 'package:vector_crisis/game/models/arrow_seed.dart';
// import 'package:vector_crisis/game/models/arrow_type.dart';
// import 'package:vector_crisis/game/models/level_data.dart';
//
// typedef _Cell = ({int row, int column});
//
// void main() {
//   final generated = <LevelData>[];
//   var previousMinimum = 4;
//
//   for (var id = 4; id <= 100; id++) {
//     final grid = _gridFor(id);
//     final types = _specialCounts(id);
//     final arithmeticFloor = 5 + ((id - 4) * 31 / 96).floor();
//     final minimumFloor = max(arithmeticFloor, previousMinimum);
//     LevelData? accepted;
//     SolverAnalysis? acceptedAnalysis;
//
//     for (var extra = 0; extra <= 7 && accepted == null; extra++) {
//       final arrowCount = min(
//         grid * grid - 4,
//         minimumFloor + types.bombs * 2 + extra,
//       );
//       print('search level=$id floor=$minimumFloor arrows=$arrowCount');
//       for (var attempt = 0; attempt < 800; attempt++) {
//         final seed = id * 100000 + extra * 1000 + attempt;
//         if (attempt == 0) print('  building sample');
//         final candidate = _candidate(
//           id: id,
//           grid: grid,
//           arrowCount: arrowCount,
//           seed: seed,
//           rotators: types.rotators,
//           frozen: types.frozen,
//           bombs: types.bombs,
//         );
//         if (attempt == 0) print('  analyzing sample');
//         final analysis = LevelSolver.analyze(
//           candidate,
//           maxVisitedStates: 250000,
//         );
//         final minimum = analysis.minimumMoves;
//         if (attempt == 0) {
//           print(
//             '  sample minimum=$minimum initial=${analysis.initialPlayableMoves} '
//             'decisions=${analysis.decisionStates} '
//             'forced=${analysis.maxForcedMoveStreak}',
//           );
//         }
//         if (minimum == null || analysis.hitStateLimit) continue;
//         if (minimum < minimumFloor || minimum > minimumFloor + 3) continue;
//         if (analysis.initialPlayableMoves < 2 ||
//             analysis.initialPlayableMoves > 4) {
//           continue;
//         }
//         if (analysis.decisionStates < (minimum * 0.65).floor()) continue;
//         if (analysis.maxForcedMoveStreak > 4) continue;
//         if (types.rotators > 0 &&
//             !analysis.solution!.any(
//               (action) => action.type == SolverActionType.rotateClockwise,
//             )) {
//           continue;
//         }
//         accepted = LevelData(
//           id: id,
//           rows: grid,
//           columns: grid,
//           difficulty: _difficultyFor(id),
//           mechanicFocus: _focusFor(id),
//           targetMoves: minimum,
//           isChallenge: id % 10 == 0 || id == 25 || id == 75,
//           arrows: candidate.arrows,
//         );
//         acceptedAnalysis = analysis;
//         break;
//       }
//     }
//
//     if (accepted == null || acceptedAnalysis == null) {
//       stderr.writeln('Unable to generate level $id (floor $minimumFloor).');
//       exitCode = 1;
//       return;
//     }
//     generated.add(accepted);
//     previousMinimum = acceptedAnalysis.minimumMoves!;
//     print(
//       'level=$id grid=${grid}x$grid arrows=${accepted.arrows.length} '
//       'minimum=$previousMinimum initial=${acceptedAnalysis.initialPlayableMoves} '
//       'decisions=${acceptedAnalysis.decisionStates} '
//       'forced=${acceptedAnalysis.maxForcedMoveStreak} '
//       'visited=${acceptedAnalysis.visitedStates}',
//     );
//   }
//
//   File('lib/game/data/progression_levels.dart')
//       .writeAsStringSync(_render(generated));
// }
//
// LevelData _candidate({
//   required int id,
//   required int grid,
//   required int arrowCount,
//   required int seed,
//   required int rotators,
//   required int frozen,
//   required int bombs,
// }) {
//   final debug = seed == 400000;
//   final random = Random(seed);
//   final cells = <_Cell>[
//     for (var row = 0; row < grid; row++)
//       for (var column = 0; column < grid; column++) (row: row, column: column),
//   ];
//   final patternScores = <_Cell, double>{
//     for (final cell in cells)
//       cell: _patternScore(cell, grid, id) + random.nextDouble() * 0.42,
//   };
//   if (debug) print('    scores ready');
//   cells.sort((a, b) {
//     return patternScores[a]!.compareTo(patternScores[b]!);
//   });
//   if (debug) print('    cells sorted');
//   final selected = cells.take(arrowCount).toList();
//   if (debug) print('    selected ${selected.length}');
//   selected.sort(
//     (a, b) => _rankScore(a, grid, id).compareTo(_rankScore(b, grid, id)),
//   );
//   if (debug) print('    selected sorted');
//   final rank = <_Cell, int>{
//     for (var index = 0; index < selected.length; index++)
//       selected[index]: index,
//   };
//   if (debug) print('    rank map ready');
//   final occupied = selected.toSet();
//   if (debug) print('    ranks ready');
//
//   final finalDirections = <_Cell, ArrowDirection>{};
//   for (final cell in selected) {
//     final valid = <({ArrowDirection direction, int blockers})>[];
//     for (final direction in ArrowDirection.values) {
//       final ahead = _ahead(
//         cell,
//         direction,
//         grid,
//       ).where(occupied.contains).toList();
//       if (ahead.every((other) => rank[other]! < rank[cell]!)) {
//         valid.add((direction: direction, blockers: ahead.length));
//       }
//     }
//     if (valid.isEmpty) {
//       return const LevelData(id: -1, rows: 1, columns: 1, arrows: []);
//     }
//     valid.sort((a, b) => b.blockers.compareTo(a.blockers));
//     final bestBlockers = valid.first.blockers;
//     final preferred = valid
//         .where((option) => option.blockers == bestBlockers)
//         .toList();
//     finalDirections[cell] =
//         preferred[random.nextInt(preferred.length)].direction;
//   }
//   if (debug) print('    directions ready');
//
//   final typeByCell = <_Cell, ArrowType>{};
//   final bombCandidates = [...selected]
//     ..sort((a, b) {
//       int futureNeighbours(_Cell cell) => _neighbours(cell, grid)
//           .where(occupied.contains)
//           .where((other) => rank[other]! > rank[cell]!)
//           .length;
//       return futureNeighbours(b).compareTo(futureNeighbours(a));
//     });
//   for (final cell in bombCandidates.take(bombs)) {
//     typeByCell[cell] = ArrowType.bomb;
//   }
//   if (debug) print('    bombs ready');
//
//   final frozenCandidates =
//       selected
//           .where((cell) => !typeByCell.containsKey(cell))
//           .where(
//             (cell) => _neighbours(cell, grid).any(
//               (other) => occupied.contains(other) && rank[other]! < rank[cell]!,
//             ),
//           )
//           .toList()
//         ..sort((a, b) => rank[b]!.compareTo(rank[a]!));
//   for (final cell in frozenCandidates.take(frozen)) {
//     typeByCell[cell] = ArrowType.frozen;
//   }
//   if (debug) print('    frozen ready');
//
//   final rotatorCandidates = selected
//       .where((cell) => !typeByCell.containsKey(cell))
//       .where((cell) => rank[cell]! > selected.length ~/ 4)
//       .toList();
//   final rotatorScores = <_Cell, double>{
//     for (final cell in rotatorCandidates) cell: random.nextDouble(),
//   };
//   rotatorCandidates.sort(
//     (a, b) => rotatorScores[a]!.compareTo(rotatorScores[b]!),
//   );
//   for (final cell in rotatorCandidates.take(rotators)) {
//     typeByCell[cell] = ArrowType.rotator;
//   }
//   if (debug) print('    rotators ready');
//
//   final arrows = <ArrowSeed>[];
//   for (final cell in selected) {
//     final type = typeByCell[cell] ?? ArrowType.normal;
//     var direction = finalDirections[cell]!;
//     if (type == ArrowType.rotator) {
//       direction = _counterClockwise(direction);
//     }
//     arrows.add(
//       ArrowSeed(
//         row: cell.row,
//         column: cell.column,
//         direction: direction,
//         type: type,
//       ),
//     );
//   }
//   if (debug) print('    arrows ready');
//   return LevelData(id: id, rows: grid, columns: grid, arrows: arrows);
// }
//
// int _rankScore(_Cell cell, int grid, int id) {
//   final row = switch (id % 8) {
//     2 || 3 || 6 || 7 => grid - 1 - cell.row,
//     _ => cell.row,
//   };
//   final column = switch (id % 8) {
//     1 || 3 || 5 || 7 => grid - 1 - cell.column,
//     _ => cell.column,
//   };
//   return switch (id % 8) {
//     0 || 1 || 2 || 3 => row * grid + column,
//     _ => column * grid + row,
//   };
// }
//
// double _patternScore(_Cell cell, int grid, int id) {
//   final center = (grid - 1) / 2;
//   final dr = (cell.row - center).abs();
//   final dc = (cell.column - center).abs();
//   return switch (id % 6) {
//     0 => max(dr, dc) + ((cell.row + cell.column).isEven ? 0.0 : 0.35),
//     1 => (dr + dc) + (cell.column.isEven ? 0.0 : 0.28),
//     2 => (cell.row - cell.column).abs() * 0.45 + max(dr, dc) * 0.4,
//     3 => min(dr, dc) + ((cell.row + cell.column) % 3) * 0.18,
//     4 => dc * 0.7 + dr * 0.3 + (cell.row.isEven ? 0.0 : 0.22),
//     _ => dr * 0.7 + dc * 0.3 + (cell.column.isEven ? 0.0 : 0.22),
//   };
// }
//
// Iterable<_Cell> _ahead(_Cell cell, ArrowDirection direction, int grid) sync* {
//   var row = cell.row + direction.rowDelta;
//   var column = cell.column + direction.columnDelta;
//   while (row >= 0 && row < grid && column >= 0 && column < grid) {
//     yield (row: row, column: column);
//     row += direction.rowDelta;
//     column += direction.columnDelta;
//   }
// }
//
// Iterable<_Cell> _neighbours(_Cell cell, int grid) sync* {
//   for (final direction in ArrowDirection.values) {
//     final row = cell.row + direction.rowDelta;
//     final column = cell.column + direction.columnDelta;
//     if (row >= 0 && row < grid && column >= 0 && column < grid) {
//       yield (row: row, column: column);
//     }
//   }
// }
//
// ArrowDirection _counterClockwise(ArrowDirection direction) =>
//     switch (direction) {
//       ArrowDirection.up => ArrowDirection.left,
//       ArrowDirection.left => ArrowDirection.down,
//       ArrowDirection.down => ArrowDirection.right,
//       ArrowDirection.right => ArrowDirection.up,
//     };
//
// int _gridFor(int id) => switch (id) {
//   <= 5 => 4,
//   <= 12 => 5,
//   <= 30 => 6,
//   <= 60 => 7,
//   _ => 8,
// };
//
// int _difficultyFor(int id) => 1 + ((id - 1) * 9 / 99).floor();
//
// ({int rotators, int frozen, int bombs}) _specialCounts(int id) => switch (id) {
//   <= 5 => (rotators: 0, frozen: 0, bombs: 0),
//   <= 7 => (rotators: 1, frozen: 0, bombs: 0),
//   <= 9 => (rotators: 1, frozen: 1, bombs: 0),
//   <= 15 => (rotators: 1, frozen: 1, bombs: 1),
//   <= 25 => (rotators: min(4, 1 + (id - 16) ~/ 3), frozen: 0, bombs: 0),
//   <= 35 => (
//     rotators: id >= 31 ? 1 : 0,
//     frozen: min(5, 2 + (id - 26) ~/ 3),
//     bombs: 0,
//   ),
//   <= 45 => (
//     rotators: id >= 41 ? 1 : 0,
//     frozen: id >= 40 ? 1 : 0,
//     bombs: min(4, 1 + (id - 36) ~/ 3),
//   ),
//   <= 60 => (rotators: 2 + (id % 3), frozen: 2 + (id % 2), bombs: 1 + (id % 2)),
//   <= 75 => (
//     rotators: 2 + (id % 3),
//     frozen: 2 + ((id + 1) % 3),
//     bombs: 1 + (id % 3 == 0 ? 1 : 0),
//   ),
//   <= 90 => (rotators: 3 + (id % 2), frozen: 3 + ((id + 1) % 2), bombs: 2),
//   _ => (rotators: 4, frozen: 4, bombs: 2 + (id % 2)),
// };
//
// String _focusFor(int id) => switch (id) {
//   <= 5 => 'directional dependency foundation',
//   <= 7 => 'rotator reading',
//   <= 9 => 'frozen dependency reading',
//   <= 15 => 'early mixed efficiency',
//   <= 25 => 'rotator progression',
//   <= 35 => 'frozen progression',
//   <= 45 => 'bomb efficiency progression',
//   <= 60 => 'mixed mechanic depth',
//   <= 75 => 'dense dependency control',
//   <= 90 => 'advanced move economy',
//   _ => 'mastery move economy',
// };
//
// String _render(List<LevelData> levels) {
//   final buffer = StringBuffer()
//     ..writeln("import '../models/arrow_direction.dart';")
//     ..writeln("import '../models/arrow_seed.dart';")
//     ..writeln("import '../models/level_data.dart';")
//     ..writeln()
//     ..writeln('const progressionLevels = <LevelData>[');
//   for (final level in levels) {
//     buffer
//       ..writeln('  LevelData(')
//       ..writeln('    id: ${level.id},')
//       ..writeln('    rows: ${level.rows},')
//       ..writeln('    columns: ${level.columns},')
//       ..writeln('    difficulty: ${level.difficulty},')
//       ..writeln("    mechanicFocus: '${level.mechanicFocus}',")
//       ..writeln('    targetMoves: ${level.targetMoves},');
//     if (level.isChallenge) buffer.writeln('    isChallenge: true,');
//     buffer.writeln('    arrows: [');
//     for (final arrow in level.arrows) {
//       buffer.writeln(
//         '      ArrowSeed.${arrow.type.name}(${arrow.row}, ${arrow.column}, '
//         'ArrowDirection.${arrow.direction.name}),',
//       );
//     }
//     buffer
//       ..writeln('    ],')
//       ..writeln('  ),');
//   }
//   return (buffer..writeln('];')).toString();
// }
