// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:vector_crisis/game/logic/board_engine.dart';
import 'package:vector_crisis/game/logic/level_difficulty.dart';
import 'package:vector_crisis/game/logic/level_solver.dart';
import 'package:vector_crisis/game/models/level_data.dart';

import 'campaign_writer.dart';
import 'level_forge.dart';
import 'level_plan.dart';

const _solverStateBudget = 150000;
const _shapeProbe = 80;
const _playoutProbes = 64;
const _difficultySamples = 240;
const _seedsPerShape = 70;
const _motifs = 6;
const _candidateTarget = 40;

/// Escalation when a level cannot be built: extra Rotators waste moves, and
/// on Stone levels an extra Stone adds another way to jam the board.
const _escalation = <({int rotators, int stones, int gears})>[
  (rotators: 0, stones: 0, gears: 0),
  (rotators: 0, stones: 0, gears: 1),
  (rotators: 0, stones: 1, gears: 1),
  (rotators: 1, stones: 1, gears: 1),
  (rotators: 1, stones: 1, gears: 2),
];

/// Usage: `generate_levels.dart [from] [to] [--write] [--floor=N]`
///
/// With `--write` the range is written to `lib/game/data/campaign/` as its
/// own file, so several ranges can be generated in parallel. `--floor` seeds
/// the optimum of the level before `from`, which keeps the ramp monotone
/// across range boundaries.
void main(List<String> args) {
  final positional = args.where((arg) => !arg.startsWith('--')).toList();
  final from = positional.isNotEmpty
      ? int.parse(positional[0])
      : LevelPlan.firstGeneratedLevel;
  final to = positional.length > 1
      ? int.parse(positional[1])
      : LevelPlan.lastLevel;
  final write = args.contains('--write');
  final floorArg = args.where((arg) => arg.startsWith('--floor='));

  final accepted = <LevelData>[];
  final signatures = <String>{};
  var previousMinimum = floorArg.isEmpty
      ? 0
      : int.parse(floorArg.first.substring('--floor='.length));
  final stopwatch = Stopwatch()..start();

  for (var id = from; id <= to; id++) {
    final floor = max(LevelPlan.movesFloor(id), previousMinimum);
    final hasStones = id >= LevelPlan.firstStoneLevel;
    final hasGears = id >= LevelPlan.firstGearLevel;
    _Forged? result;
    for (final extra in _escalation) {
      if (result != null) break;
      if (extra.stones > 0 && !hasStones) continue;
      if (extra.gears > 0 && !hasGears) continue;
      result = _forgeLevel(id, floor, signatures, extra: extra);
    }
    // Last resort: accept a longer optimum rather than stall the campaign.
    // The overshoot penalty still prefers the shortest board that passes.
    result ??= _forgeLevel(
      id,
      floor,
      signatures,
      extra: (rotators: 1, stones: hasStones ? 1 : 0, gears: hasGears ? 1 : 0),
      extraCeiling: 2,
    );

    if (result == null) {
      stderr.writeln('FAILED level $id (floor $floor)');
      exitCode = 1;
      return;
    }

    accepted.add(result.level);
    signatures.add(_signature(result.level));
    previousMinimum = result.level.targetMoves!;

    print(
      'level=$id ${result.level.rows}x${result.level.columns} '
      'arrows=${result.level.arrows.length} '
      'min=${result.level.targetMoves} floor=$floor '
      'limit=${result.level.moveLimit} '
      'openings=${result.openings} '
      'unplanned3star=${(result.report.sensibleOptimalRate * 100).round()}% '
      'unplannedFail=${(result.report.sensibleFailureRate * 100).round()}% '
      'waste=${result.report.wasteMargin.toStringAsFixed(1)} '
      'stones=${result.stones} '
      'unplannedStuck=${_pct(result.report.sensibleStuckRate)} '
      'carefulFail=${_pct(result.report.carefulFailureRate)} '
      'strategist3star=${_pct(result.report.strategistOptimalRate)} '
      'strategistFail=${_pct(result.report.strategistFailureRate)} '
      'careful3star=${_pct(result.report.carefulOptimalRate)} '
      'tried=${result.tried}',
    );
  }

  stopwatch.stop();
  print(
    'generated ${accepted.length} levels in ${stopwatch.elapsed.inSeconds}s',
  );

  if (write) {
    final name = campaignPartName(from, to);
    final path = 'lib/game/data/campaign/$name.dart';
    File(path)
      ..createSync(recursive: true)
      ..writeAsStringSync(renderCampaignPart(accepted, from, to));
    print('wrote $path');
  }
}

String _pct(double rate) => '${(rate * 100).round()}%';

class _Forged {
  final LevelData level;
  final DifficultyReport report;
  final int openings;
  final int stones;
  final int tried;
  final double score;

  const _Forged({
    required this.level,
    required this.report,
    required this.openings,
    required this.stones,
    required this.tried,
    required this.score,
  });
}

_Forged? _forgeLevel(
  int id,
  int floor,
  Set<String> taken, {
  required ({int rotators, int stones, int gears}) extra,
  int extraCeiling = 0,
}) {
  final grid = LevelPlan.grid(id);
  final cells = grid * grid;
  final cellCap = min(BoardEngine.maxArrows, (cells * 0.68).floor());
  // Measured against the plan rather than the floor, so one long level cannot
  // drag every later level upward with it.
  // At least two values stay open, or the window can shrink to a single
  // optimum that no forged board happens to hit.
  final ceiling = max(floor + 1, LevelPlan.movesFloor(id) + 2) + extraCeiling;
  final optimalCeiling = LevelPlan.maxUnplannedOptimalRate(id);
  final failureFloor = LevelPlan.minUnplannedFailureRate(id);
  final carefulFloor = LevelPlan.minCarefulFailureRate(id);
  final stuckFloor = LevelPlan.minUnplannedStuckRate(id);
  final strategistCeiling = LevelPlan.maxStrategistOptimalRate(id);
  final strategistFloor = LevelPlan.minStrategistFailureRate(id);

  _Forged? best;
  var tried = 0;
  var passing = 0;
  final rejected = <String, int>{};
  void reject(String reason) => rejected[reason] = (rejected[reason] ?? 0) + 1;

  final shapes = <int>[
    for (var delta = -3; delta <= 9; delta++)
      if (floor + delta >= 3 && floor + delta <= cellCap) floor + delta,
  ];

  for (final arrowCount in shapes) {
    final plan = LevelPlan.specials(id, arrowCount);
    final quota = (
      rotators: plan.rotators + extra.rotators,
      frozen: plan.frozen,
      bombs: plan.bombs,
      stones: plan.stones == 0 ? 0 : plan.stones + extra.stones,
      gears: plan.gears == 0 ? 0 : plan.gears + extra.gears,
    );
    final stateBits =
        arrowCount +
        quota.rotators * 2 +
        quota.stones * 3 +
        (quota.gears > 0 ? 2 : 0);
    if (stateBits > BoardEngine.maxStateBits) continue;
    var inWindow = 0;
    var solved = 0;
    for (var attempt = 0; attempt < _seedsPerShape * _motifs; attempt++) {
      if (passing >= _candidateTarget) break;
      // An arrow count that never lands in the window is not worth the rest
      // of its seeds.
      if (solved >= _shapeProbe && inWindow == 0) break;
      tried++;

      final candidate = LevelForge.build(
        ForgeRequest(
          id: id,
          rows: grid,
          columns: grid,
          arrowCount: arrowCount,
          rotators: quota.rotators,
          frozen: quota.frozen,
          bombs: quota.bombs,
          stones: quota.stones,
          gears: quota.gears,
          motif: attempt % _motifs,
          tight: attempt ~/ _motifs % 2 == 1,
          seed: id * 1000003 + arrowCount * 9973 + attempt,
        ),
      );
      if (candidate == null) {
        reject('unbuildable');
        continue;
      }
      if (taken.contains(_signature(candidate))) {
        reject('duplicate');
        continue;
      }

      // Cheap checks first: the full search is what makes generation slow.
      final board = BoardEngine(candidate);
      final exits = board.exitableCount(board.allMask, 0);
      if (exits < 2 || exits > LevelPlan.maxOpenings(id)) {
        reject('openings');
        continue;
      }
      if (board.movesLowerBound(board.allMask) > ceiling) {
        reject('optimum above ceiling');
        continue;
      }
      if (_shortestPlayout(board, floor, attempt) < floor) {
        reject('optimum below floor');
        continue;
      }

      solved++;
      final analysis = LevelSolver.analyzeBoard(
        board,
        maxVisitedStates: _solverStateBudget,
      );
      if (!analysis.isSolvable || analysis.hitStateLimit) {
        reject('solver budget');
        continue;
      }

      final minimum = analysis.minimumMoves!;
      if (minimum < floor) {
        reject('optimum below floor');
        continue;
      }
      if (minimum > ceiling) {
        reject('optimum above ceiling');
        continue;
      }
      inWindow++;

      // The levels that introduce the Rotator have to make the player turn
      // one, otherwise the hint fires on a board that never needs the move.
      if (id >= 6 && id <= 9) {
        final turns = analysis.solution!.any(
          (action) => action.type == SolverActionType.rotateClockwise,
        );
        if (!turns) {
          reject('rotator unused');
          continue;
        }
      }

      final level = LevelData(
        id: id,
        rows: grid,
        columns: grid,
        difficulty: LevelPlan.difficulty(id),
        mechanicFocus: LevelPlan.focus(id),
        targetMoves: minimum,
        isChallenge: LevelPlan.isChallenge(id),
        arrows: candidate.arrows,
      );

      final report = LevelDifficulty.measure(
        level,
        samples: _difficultySamples,
        minimumMoves: minimum,
      );
      if (report.sensibleOptimalRate > optimalCeiling) {
        reject('too many unplanned 3 stars');
        continue;
      }
      if (report.sensibleFailureRate < failureFloor) {
        reject('too few unplanned failures');
        continue;
      }
      if (report.sensibleStuckRate < stuckFloor) {
        reject('stones never jam the board');
        continue;
      }
      if (report.carefulFailureRate < carefulFloor) {
        reject('careful play wins too often');
        continue;
      }
      if (report.strategistOptimalRate > strategistCeiling) {
        reject('worked-out strategy three-stars it');
        continue;
      }
      if (report.strategistFailureRate < strategistFloor) {
        reject('worked-out strategy never loses');
        continue;
      }

      passing++;
      final score =
          3.0 * (1 - report.sensibleOptimalRate) +
          2.0 * min(report.sensibleFailureRate, 0.85) +
          0.5 * min(report.wasteMargin, 6) / 6 +
          0.5 * (1 - report.carelessOptimalRate) +
          3.0 * min(report.carefulFailureRate, 0.8) +
          5.0 * (1 - report.strategistOptimalRate) +
          4.0 * min(report.strategistFailureRate, 0.9) +
          1.0 * report.sensibleStuckRate -
          4.0 * (minimum - floor);

      if (best == null || score > best.score) {
        best = _Forged(
          level: level,
          report: report,
          openings: analysis.initialExitOptions,
          stones: quota.stones,
          tried: tried,
          score: score,
        );
      }
    }
    if (passing >= _candidateTarget) break;
  }

  if (best == null) {
    stderr.writeln(
      '  level $id +${extra.rotators} rotators +${extra.stones} stones '
      '+$extraCeiling ceiling '
      'rejected: $rejected',
    );
  }
  return best;
}

/// Length of the shortest of a few random clears. Any clear is an upper
/// bound on the optimum, so a result under [floor] rules the board out
/// without a full search.
int _shortestPlayout(BoardEngine board, int floor, int seed) {
  final random = Random(seed);
  final buffer = List<int>.filled(board.arrowCount, 0);
  var best = 1 << 30;
  for (var run = 0; run < _playoutProbes; run++) {
    var key = board.allMask;
    var moves = 0;
    while (key & board.allMask != 0 && moves < best && moves < floor) {
      final alive = key & board.allMask;
      final aux = key >> board.arrowCount;
      var count = board.collectExitable(alive, aux, buffer);
      if (count == 0) count = board.collectPlayable(alive, aux, buffer);
      if (count == 0) break;
      moves++;
      key = board.move(buffer[random.nextInt(count)], key);
    }
    if (key & board.allMask == 0 && moves < best) best = moves;
    if (best < floor) break;
  }
  return best;
}

String _signature(LevelData level) {
  final arrows =
      level.arrows
          .map(
            (arrow) =>
                '${arrow.row}:${arrow.column}:'
                '${arrow.direction.name}:${arrow.type.name}',
          )
          .toList()
        ..sort();
  return '${level.rows}x${level.columns}|${arrows.join('|')}';
}
