// ignore_for_file: avoid_print

import 'dart:io';

import 'package:vector_crisis/game/data/levels.dart';
import 'package:vector_crisis/game/logic/level_difficulty.dart';
import 'package:vector_crisis/game/models/level_data.dart';

import 'campaign_writer.dart';
import 'level_plan.dart';

/// Renumbers the generated levels so the optimum never drops.
///
/// Ranges are generated in parallel, which means a range can end on a longer
/// level than the next range starts with. The boards themselves are fine, so
/// rather than regenerating hours of work, every level from the first Gear
/// level on is sorted by its optimum and handed a new id. Levels before that
/// keep their place: they are the mechanic introductions, in the order the
/// in-game hints announce.
///
/// Levels that cost the same number of moves go weakest first, so a board
/// that only just punishes a routine lands on a lower id, where the
/// difficulty gates ask less of it.
void main() {
  const firstSorted = LevelPlan.firstGearLevel;
  final fixed = levels.where((level) => level.id < firstSorted).toList();
  final candidates = levels.where((level) => level.id >= firstSorted).toList();
  final bite = <int, double>{
    for (final level in candidates) level.id: _bite(level),
  };
  final sorted = candidates
    ..sort((a, b) {
      final byMoves = a.targetMoves!.compareTo(b.targetMoves!);
      if (byMoves != 0) return byMoves;
      return bite[a.id]!.compareTo(bite[b.id]!);
    });

  final renumbered = <LevelData>[];
  for (var index = 0; index < sorted.length; index++) {
    final id = firstSorted + index;
    final level = sorted[index];
    renumbered.add(
      LevelData(
        id: id,
        rows: level.rows,
        columns: level.columns,
        difficulty: LevelPlan.difficulty(id),
        mechanicFocus: LevelPlan.focus(id),
        targetMoves: level.targetMoves,
        isChallenge: LevelPlan.isChallenge(id),
        arrows: level.arrows,
      ),
    );
  }

  final catalog = [...fixed, ...renumbered];
  for (
    var index = LevelPlan.firstGeneratedLevel;
    index < catalog.length;
    index++
  ) {
    final before = catalog[index - 1].targetMoves ?? 0;
    final after = catalog[index].targetMoves ?? 0;
    if (after < before) {
      stderr.writeln(
        'still dropping at ${catalog[index].id}: $before > $after',
      );
      exitCode = 1;
      return;
    }
  }

  for (final range in campaignRanges) {
    final part = catalog
        .where((level) => level.id >= range.$1 && level.id <= range.$2)
        .toList();
    File('lib/game/data/campaign/${campaignPartName(range.$1, range.$2)}.dart')
        .writeAsStringSync(renderCampaignPart(part, range.$1, range.$2));
  }
  print(
    'renumbered ${renumbered.length} levels across '
    '${campaignRanges.length} files',
  );
}

/// How hard a level bites: how often each simulated player loses it, minus a
/// penalty for handing three stars to a routine.
double _bite(LevelData level) {
  final report = LevelDifficulty.measure(
    level,
    samples: 240,
    minimumMoves: level.targetMoves,
  );
  return report.strategistFailureRate +
      report.carefulFailureRate +
      report.sensibleFailureRate -
      report.strategistOptimalRate * 2;
}
