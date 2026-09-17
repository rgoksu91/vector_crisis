import '../models/arrow_direction.dart';
import '../models/arrow_seed.dart';
import '../models/level_data.dart';
import 'campaign_levels.dart';

/// Levels 1-3 are hand-made tutorials; everything after them is generated
/// by tool/generate_levels.dart.
const levels = <LevelData>[
  LevelData(
    id: 1,
    rows: 3,
    columns: 3,
    arrows: [ArrowSeed(row: 1, column: 2, direction: ArrowDirection.right)],
  ),
  LevelData(
    id: 2,
    rows: 3,
    columns: 3,
    arrows: [
      ArrowSeed(row: 1, column: 0, direction: ArrowDirection.right),
      ArrowSeed(row: 1, column: 2, direction: ArrowDirection.right),
    ],
  ),
  LevelData(
    id: 3,
    rows: 3,
    columns: 3,
    arrows: [
      ArrowSeed(row: 0, column: 1, direction: ArrowDirection.up),
      ArrowSeed(row: 1, column: 0, direction: ArrowDirection.left),
      ArrowSeed(row: 2, column: 1, direction: ArrowDirection.down),
      ArrowSeed(row: 1, column: 2, direction: ArrowDirection.right),
    ],
  ),
  ...campaignLevels,
];
