// ignore_for_file: avoid_print

import 'package:vector_crisis/game/data/levels.dart';
import 'package:vector_crisis/game/logic/level_difficulty.dart';
import 'package:vector_crisis/game/logic/level_solver.dart';
import 'package:vector_crisis/game/models/arrow_direction.dart';
import 'package:vector_crisis/game/models/arrow_type.dart';
import 'package:vector_crisis/game/models/level_data.dart';

import 'level_plan.dart';

/// Catalog report behind LEVEL_AUDIT.md: `dart run tool/level_audit.dart`.

void main() {
  var tutorialFingerprint = 17;
  for (final level in levels.take(3)) {
    tutorialFingerprint = _mix(tutorialFingerprint, level.id);
    tutorialFingerprint = _mix(tutorialFingerprint, level.rows);
    tutorialFingerprint = _mix(tutorialFingerprint, level.columns);
    for (final arrow in level.arrows) {
      tutorialFingerprint = _mix(tutorialFingerprint, arrow.row);
      tutorialFingerprint = _mix(tutorialFingerprint, arrow.column);
      tutorialFingerprint = _mix(tutorialFingerprint, arrow.direction.index);
      tutorialFingerprint = _mix(tutorialFingerprint, arrow.type.index);
    }
  }

  print('tutorialFingerprint=$tutorialFingerprint');
  print(
    'id,grid,arrows,stones,gears,difficulty,target,minimum,openings,visited,'
    'unplanned3star,unplannedFail,unplannedJam,carefulFail,strategist3star,'
    'strategistFail,focus',
  );
  final analyses = <int, SolverAnalysis>{};
  final reports = <int, DifficultyReport>{};
  final gateMisses = <String>[];
  for (final level in levels) {
    final analysis = LevelSolver.analyze(level);
    analyses[level.id] = analysis;
    final report = LevelDifficulty.measure(
      level,
      samples: 240,
      minimumMoves: analysis.minimumMoves,
    );
    reports[level.id] = report;
    if (level.id >= LevelPlan.firstGeneratedLevel) {
      final misses = _gateMisses(level.id, report);
      if (misses.isNotEmpty) gateMisses.add('${level.id}:${misses.join('/')}');
    }
    print(
      '${level.id},${level.rows}x${level.columns},${level.arrows.length},'
      '${level.arrows.where((arrow) => arrow.type == ArrowType.stone).length},'
      '${level.arrows.where((arrow) => arrow.type == ArrowType.gear).length},'
      '${level.difficulty},${level.targetMoves ?? '-'},'
      '${analysis.minimumMoves ?? 'UNSOLVABLE'},'
      '${analysis.initialExitOptions},${analysis.visitedStates},'
      '${_pct(report.sensibleOptimalRate)},${_pct(report.sensibleFailureRate)},'
      '${_pct(report.sensibleStuckRate)},${_pct(report.carefulFailureRate)},'
      '${_pct(report.strategistOptimalRate)},'
      '${_pct(report.strategistFailureRate)},'
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
        analyses[a.id]!.initialExitOptions >= analyses[b.id]!.initialExitOptions
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
    '${analyses[mostOpen.id]!.initialExitOptions}',
  );
  print(
    'summary.totalOptimalMoves='
    '${levels.fold<int>(0, (sum, level) => sum + analyses[level.id]!.minimumMoves!)}',
  );
  for (final band in _bands) {
    final inBand = levels.where(
      (level) => level.id >= band.$1 && level.id <= band.$2,
    );
    double mean(double Function(DifficultyReport) pick) =>
        inBand.fold<double>(0, (sum, level) => sum + pick(reports[level.id]!)) /
        inBand.length;
    final moves = inBand.map((level) => analyses[level.id]!.minimumMoves!);
    print(
      'summary.band=${band.$1}-${band.$2} levels=${inBand.length} '
      'moves=${moves.reduce((a, b) => a < b ? a : b)}-'
      '${moves.reduce((a, b) => a > b ? a : b)} '
      'unplanned3star=${_pct(mean((r) => r.sensibleOptimalRate))} '
      'unplannedFail=${_pct(mean((r) => r.sensibleFailureRate))} '
      'unplannedJam=${_pct(mean((r) => r.sensibleStuckRate))} '
      'carefulFail=${_pct(mean((r) => r.carefulFailureRate))} '
      'careful3star=${_pct(mean((r) => r.carefulOptimalRate))} '
      'strategist3star=${_pct(mean((r) => r.strategistOptimalRate))} '
      'strategistFail=${_pct(mean((r) => r.strategistFailureRate))}',
    );
  }
  var rampDrops = <String>[];
  for (var i = LevelPlan.firstGeneratedLevel; i < levels.length; i++) {
    final before = levels[i - 1].targetMoves ?? 0;
    final after = levels[i].targetMoves ?? 0;
    if (after < before) rampDrops.add('${levels[i].id}:$before>$after');
  }
  print('summary.rampDrops=$rampDrops');
  print('summary.gateMisses=$gateMisses');
  // Both figures describe the one shortest path the solver returned, not the
  // level itself, so they are informational. A forced run in the middle of
  // that path is worth a look; a forced run at the very end is just the last
  // arrows being cleared.
  final corridors = <String>[];
  final forcedEndings = <String>[];
  for (final level in levels.where((level) => level.id >= 10)) {
    final counts = analyses[level.id]!.playableMovesAlongSolution;
    var tail = 0;
    while (tail < counts.length && counts[counts.length - 1 - tail] == 1) {
      tail++;
    }
    final middle = counts.sublist(0, counts.length - tail);
    if (_longestForcedRun(middle) > 4) {
      corridors.add('${level.id}:$counts');
    }
    if (tail > 4) forcedEndings.add('${level.id}:$tail');
  }
  print('summary.midSolutionCorridors=$corridors');
  print('summary.forcedEndings=$forcedEndings');

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

const _bands = [
  (4, 11),
  (12, 50),
  (51, 100),
  (101, 150),
  (151, 200),
  (201, 250),
  (251, 300),
];

String _pct(double rate) => '${(rate * 100).round()}%';

List<String> _gateMisses(int id, DifficultyReport report) => [
  if (report.sensibleOptimalRate > LevelPlan.maxUnplannedOptimalRate(id))
    'unplanned3star',
  if (report.sensibleFailureRate < LevelPlan.minUnplannedFailureRate(id))
    'unplannedFail',
  if (report.sensibleStuckRate < LevelPlan.minUnplannedStuckRate(id))
    'unplannedJam',
  if (report.carefulFailureRate < LevelPlan.minCarefulFailureRate(id))
    'carefulFail',
  if (report.strategistOptimalRate > LevelPlan.maxStrategistOptimalRate(id))
    'strategist3star',
  if (report.strategistFailureRate < LevelPlan.minStrategistFailureRate(id))
    'strategistFail',
];

int _longestForcedRun(List<int> counts) {
  var longest = 0;
  var current = 0;
  for (final count in counts) {
    current = count == 1 ? current + 1 : 0;
    if (current > longest) longest = current;
  }
  return longest;
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
