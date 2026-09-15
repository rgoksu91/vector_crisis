// ignore_for_file: avoid_print

import 'package:vector_crisis/game/data/levels.dart';
import 'package:vector_crisis/game/logic/level_solver.dart';
import 'package:vector_crisis/game/models/arrow_direction.dart';
import 'package:vector_crisis/game/models/arrow_type.dart';
import 'package:vector_crisis/game/models/level_data.dart';

void main() {
  var baselineFingerprint = 17;
  for (final level in levels.take(9)) {
    baselineFingerprint = _mix(baselineFingerprint, level.id);
    baselineFingerprint = _mix(baselineFingerprint, level.rows);
    baselineFingerprint = _mix(baselineFingerprint, level.columns);
    for (final arrow in level.arrows) {
      baselineFingerprint = _mix(baselineFingerprint, arrow.row);
      baselineFingerprint = _mix(baselineFingerprint, arrow.column);
      baselineFingerprint = _mix(baselineFingerprint, arrow.direction.index);
      baselineFingerprint = _mix(baselineFingerprint, arrow.type.index);
    }
  }

  print('baselineFingerprint=$baselineFingerprint');
  print(
    'id,grid,arrows,difficulty,target,minimum,initial,decisions,'
    'maxForcedStreak,visited,focus',
  );
  final analyses = <int, SolverAnalysis>{};
  for (final level in levels) {
    final analysis = LevelSolver.analyze(level);
    analyses[level.id] = analysis;
    print(
      '${level.id},${level.rows}x${level.columns},${level.arrows.length},'
      '${level.difficulty},${level.targetMoves ?? '-'},'
      '${analysis.minimumMoves ?? 'UNSOLVABLE'},'
      '${analysis.initialPlayableMoves},${analysis.decisionStates},'
      '${analysis.maxForcedMoveStreak},${analysis.visitedStates},'
      '${level.mechanicFocus}',
    );
  }

  final gridCounts = <String, int>{};
  final difficultyCounts = <int, int>{};
  final typeLevelCounts = {for (final type in ArrowType.values) type: 0};
  var mixedLevels = 0;
  for (final level in levels) {
    gridCounts.update(
      '${level.rows}x${level.columns}',
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    difficultyCounts.update(
      level.difficulty,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    for (final type in level.arrows.map((arrow) => arrow.type).toSet()) {
      typeLevelCounts[type] = typeLevelCounts[type]! + 1;
    }
    final specialTypes = level.arrows
        .where((arrow) => arrow.type != ArrowType.normal)
        .map((arrow) => arrow.type)
        .toSet();
    if (specialTypes.length >= 2) mixedLevels++;
  }

  final highestMoves = levels.reduce(
    (a, b) =>
        analyses[a.id]!.minimumMoves! >= analyses[b.id]!.minimumMoves! ? a : b,
  );
  final mostSpecial = levels.reduce((a, b) {
    int count(LevelData level) =>
        level.arrows.where((arrow) => arrow.type != ArrowType.normal).length;
    return count(a) >= count(b) ? a : b;
  });
  final densest = levels.reduce((a, b) {
    double density(LevelData level) =>
        level.arrows.length / (level.rows * level.columns);
    return density(a) >= density(b) ? a : b;
  });
  final mostOpen = levels.reduce(
    (a, b) =>
        analyses[a.id]!.initialPlayableMoves >=
            analyses[b.id]!.initialPlayableMoves
        ? a
        : b,
  );

  print('summary.grid=$gridCounts');
  print('summary.difficulty=$difficultyCounts');
  print(
    'summary.typeLevels=${typeLevelCounts.map((key, value) => MapEntry(key.name, value))}',
  );
  print('summary.mixedLevels=$mixedLevels');
  print(
    'summary.challenges=${levels.where((level) => level.isChallenge).map((level) => level.id).toList()}',
  );
  print(
    'summary.breathers=${levels.where((level) => level.isBreather).map((level) => level.id).toList()}',
  );
  print(
    'summary.highestMoves=level${highestMoves.id}:${analyses[highestMoves.id]!.minimumMoves}',
  );
  print(
    'summary.mostSpecial=level${mostSpecial.id}:'
    '${mostSpecial.arrows.where((arrow) => arrow.type != ArrowType.normal).length}',
  );
  print(
    'summary.densest=level${densest.id}:'
    '${(densest.arrows.length / (densest.rows * densest.columns)).toStringAsFixed(3)}',
  );
  print(
    'summary.mostOpen=level${mostOpen.id}:'
    '${analyses[mostOpen.id]!.initialPlayableMoves}',
  );
  print(
    'summary.branchingWarnings='
    '${levels.where((level) {
      final analysis = analyses[level.id]!;
      return level.id >= 10 && (analysis.decisionStates < 2 || analysis.maxForcedMoveStreak > 4);
    }).map((level) {
      final analysis = analyses[level.id]!;
      final actions = analysis.solution!.map((action) => '${action.arrowId}/${action.type.name}').join('>');
      return '${level.id}:${analysis.playableMovesAlongSolution}:$actions';
    }).toList()}',
  );

  final similarityWarnings = <String>[];
  for (var i = 0; i < levels.length; i++) {
    for (var j = i + 1; j < levels.length; j++) {
      final similarity = _symmetrySimilarity(levels[i], levels[j]);
      if (similarity >= 0.8) {
        similarityWarnings.add(
          '${levels[i].id}/${levels[j].id}:${similarity.toStringAsFixed(2)}',
        );
      }
    }
  }
  print('summary.similarityWarnings=$similarityWarnings');
}

int _mix(int value, int part) => (value * 31 + part) & 0x7fffffff;

double _symmetrySimilarity(LevelData a, LevelData b) {
  if (a.rows != a.columns || b.rows != b.columns || a.rows != b.rows) {
    return 0;
  }

  final target = b.arrows
      .map(
        (arrow) =>
            '${arrow.row}:${arrow.column}:${arrow.direction.index}:${arrow.type.index}',
      )
      .toSet();
  var best = 0.0;
  for (var mirrored = 0; mirrored < 2; mirrored++) {
    for (var rotations = 0; rotations < 4; rotations++) {
      final transformed = a.arrows.map((arrow) {
        var row = arrow.row;
        var column = arrow.column;
        var direction = arrow.direction;
        if (mirrored == 1) {
          column = a.columns - 1 - column;
          direction = switch (direction) {
            ArrowDirection.left => ArrowDirection.right,
            ArrowDirection.right => ArrowDirection.left,
            _ => direction,
          };
        }
        for (var turn = 0; turn < rotations; turn++) {
          final nextRow = column;
          final nextColumn = a.rows - 1 - row;
          row = nextRow;
          column = nextColumn;
          direction = direction.clockwise;
        }
        return '$row:$column:${direction.index}:${arrow.type.index}';
      }).toSet();
      final intersection = transformed.intersection(target).length;
      final union = transformed.union(target).length;
      if (union > 0) {
        best = best > intersection / union ? best : intersection / union;
      }
    }
  }
  return best;
}
