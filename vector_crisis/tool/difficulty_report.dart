// ignore_for_file: avoid_print

import 'package:vector_crisis/game/data/levels.dart';
import 'package:vector_crisis/game/logic/level_difficulty.dart';
import 'package:vector_crisis/game/logic/level_solver.dart';

void main() {
  print('id,arrows,min,limit,sensible3Star%,sensibleFail%,avgWaste');
  var freeThreeStars = 0;
  var neverFails = 0;
  var regressions = <String>[];
  var previous = 0;

  for (final level in levels) {
    final analysis = LevelSolver.analyze(level);
    final report = LevelDifficulty.measure(
      level,
      minimumMoves: analysis.minimumMoves,
    );
    if (report.sensibleOptimalRate >= 0.9) freeThreeStars++;
    if (report.sensibleFailureRate == 0) neverFails++;
    if (level.id > 1 && analysis.minimumMoves! < previous) {
      regressions.add('${level.id}(${analysis.minimumMoves}<$previous)');
    }
    previous = analysis.minimumMoves!;

    print(
      '${level.id},${level.arrows.length},${analysis.minimumMoves},'
      '${report.moveLimit},'
      '${(report.sensibleOptimalRate * 100).toStringAsFixed(0)},'
      '${(report.sensibleFailureRate * 100).toStringAsFixed(0)},'
      '${report.wasteMargin.toStringAsFixed(2)}',
    );
  }

  print('---');
  print(
    'levels where unplanned play 3-stars >=90% of the time: $freeThreeStars/100',
  );
  print('levels where unplanned play never fails: $neverFails/100');
  print('difficulty regressions vs previous level: ${regressions.length}');
  print('regressions: $regressions');
}
