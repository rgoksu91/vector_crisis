import 'dart:math';

import 'package:vector_crisis/game/models/arrow_direction.dart';
import 'package:vector_crisis/game/models/arrow_seed.dart';
import 'package:vector_crisis/game/models/arrow_type.dart';
import 'package:vector_crisis/game/models/level_data.dart';

typedef Cell = ({int row, int column});

/// Recipe for one candidate board.
class ForgeRequest {
  final int id;
  final int rows;
  final int columns;
  final int arrowCount;
  final int rotators;
  final int frozen;
  final int bombs;
  final int stones;
  final int seed;

  /// Which spatial motif the cells are drawn from. Part of the search space
  /// rather than a property of the level, so a level that cannot be built as a
  /// ring can still be built as a diagonal.
  final int motif;

  /// Peel arrows that start behind something whenever one is available, so a
  /// large board does not open with a dozen free exits.
  final bool tight;

  const ForgeRequest({
    required this.id,
    required this.rows,
    required this.columns,
    required this.arrowCount,
    required this.rotators,
    required this.frozen,
    required this.bombs,
    this.stones = 0,
    required this.seed,
    required this.motif,
    this.tight = false,
  });
}

/// Builds boards that are solvable by construction.
///
/// Every arrow gets a removal rank, and its direction is chosen so that only
/// lower-ranked arrows stand on its ray. Clearing in rank order is therefore
/// always a valid solution, and because every mechanic here is monotone,
/// adding bombs or freezing cells can never take that solution away.
abstract final class LevelForge {
  static LevelData? build(ForgeRequest request) {
    final random = Random(request.seed);
    final cells = _selectCells(request, random);
    if (cells.length < request.arrowCount) return null;

    final count = cells.length;
    final index = <Cell, int>{for (var i = 0; i < count; i++) cells[i]: i};

    // Arrows on the ray from cell i towards direction d, over the full board.
    final rays = List<int>.filled(count * 4, 0);
    for (var i = 0; i < count; i++) {
      for (final direction in ArrowDirection.values) {
        var mask = 0;
        for (final cell in _ray(
          cells[i],
          direction,
          request.rows,
          request.columns,
        )) {
          final other = index[cell];
          if (other != null) mask |= 1 << other;
        }
        rays[i * 4 + direction.index] = mask;
      }
    }

    // Peel the board: at every step take an arrow whose ray is free right now
    // and point it that way. The topmost remaining arrow always qualifies, so
    // this never stalls, and replaying the peel order solves the board.
    final directions = List<ArrowDirection?>.filled(count, null);
    final blockersAtStart = List<int>.filled(count, 0);
    final order = <int>[];
    var alive = count == 0 ? 0 : (1 << count) - 1;

    while (alive != 0) {
      final ready = <int>[];
      final covered = <int>[];
      var remaining = alive;
      while (remaining != 0) {
        final bit = remaining & -remaining;
        remaining ^= bit;
        final i = bit.bitLength - 1;
        var free = false;
        var hidden = false;
        for (final direction in ArrowDirection.values) {
          final ray = rays[i * 4 + direction.index];
          if (alive & ray & ~bit == 0) {
            free = true;
            if (ray & ~bit != 0) hidden = true;
          }
        }
        if (free) ready.add(i);
        if (hidden) covered.add(i);
      }
      if (ready.isEmpty) return null;

      final pool = request.tight && covered.isNotEmpty ? covered : ready;
      final picked = pool[random.nextInt(pool.length)];
      final bit = 1 << picked;

      // Among the rays that are free now, take the one that the untouched
      // board blocks hardest, so the level opens with few real options.
      ArrowDirection? best;
      var bestBlockers = -1;
      for (final direction in ArrowDirection.values) {
        final ray = rays[picked * 4 + direction.index];
        if (alive & ray & ~bit != 0) continue;
        final blockers = _bitCount(ray & ~bit);
        if (blockers > bestBlockers ||
            (blockers == bestBlockers && random.nextBool())) {
          bestBlockers = blockers;
          best = direction;
        }
      }
      if (best == null) return null;

      directions[picked] = best;
      blockersAtStart[picked] = bestBlockers;
      order.add(picked);
      alive &= ~bit;
    }

    final rank = <Cell, int>{
      for (var step = 0; step < order.length; step++) cells[order[step]]: step,
    };
    final blockers = <Cell, int>{
      for (var i = 0; i < count; i++) cells[i]: blockersAtStart[i],
    };

    final types = _assignTypes(
      request,
      cells,
      rank,
      cells.toSet(),
      blockers,
      {for (var i = 0; i < count; i++) cells[i]: directions[i]!},
      random,
    );
    if (types == null) return null;

    final arrows = <ArrowSeed>[];
    for (var i = 0; i < count; i++) {
      final cell = cells[i];
      final type = types[cell] ?? ArrowType.normal;
      var direction = directions[i]!;
      if (type == ArrowType.rotator) {
        // Store the arrow turned back from the direction that works, so the
        // player has to weigh spending turns now against waiting for the ray
        // to clear. Offset 0 keeps a Rotator that must never be turned at all.
        final offset = _rotatorOffset(request, random);
        for (var turn = 0; turn < offset; turn++) {
          direction = _counterClockwise(direction);
        }
      }
      arrows.add(
        ArrowSeed(
          row: cell.row,
          column: cell.column,
          direction: direction,
          type: type,
        ),
      );
    }

    return LevelData(
      id: request.id,
      rows: request.rows,
      columns: request.columns,
      arrows: arrows,
    );
  }

  static int _bitCount(int value) {
    var count = 0;
    var bits = value;
    while (bits != 0) {
      bits &= bits - 1;
      count++;
    }
    return count;
  }

  static int _rotatorOffset(ForgeRequest request, Random random) {
    final roll = random.nextInt(100);
    if (roll < 30) return 0;
    if (roll < 70) return 1;
    if (roll < 92) return 2;
    return 3;
  }

  static Map<Cell, ArrowType>? _assignTypes(
    ForgeRequest request,
    List<Cell> cells,
    Map<Cell, int> rank,
    Set<Cell> occupied,
    Map<Cell, int> blockersAtStart,
    Map<Cell, ArrowDirection> directions,
    Random random,
  ) {
    final types = <Cell, ArrowType>{};

    int liveNeighbours(Cell cell) => _neighbours(
      cell,
      request.rows,
      request.columns,
    ).where(occupied.contains).length;

    // Bombs earn their move by going off while the board is still crowded, so
    // favour cells that start with the most neighbours.
    if (request.bombs > 0) {
      final candidates =
          cells.where((cell) => liveNeighbours(cell) >= 2).toList()
            ..sort((a, b) {
              final byCrowd = liveNeighbours(b).compareTo(liveNeighbours(a));
              if (byCrowd != 0) return byCrowd;
              return rank[a]!.compareTo(rank[b]!);
            });
      if (candidates.length < request.bombs) return null;
      for (final cell in candidates.take(request.bombs)) {
        types[cell] = ArrowType.bomb;
      }
    }

    // A Frozen arrow only thaws when a neighbour leaves, so it must have one
    // that goes first.
    if (request.frozen > 0) {
      final candidates =
          cells
              .where((cell) => !types.containsKey(cell))
              .where(
                (cell) => _neighbours(cell, request.rows, request.columns).any(
                  (other) =>
                      occupied.contains(other) && rank[other]! < rank[cell]!,
                ),
              )
              .toList()
            ..shuffle(random);
      if (candidates.length < request.frozen) return null;
      for (final cell in candidates.take(request.frozen)) {
        types[cell] = ArrowType.frozen;
      }
    }

    if (request.stones > 0) {
      final stones = _pickStones(
        request,
        cells.where((cell) => !types.containsKey(cell)).toList(),
        cells,
        rank,
        occupied,
        directions,
        random,
      );
      if (stones == null) return null;
      for (final cell in stones) {
        types[cell] = ArrowType.stone;
      }
    }

    // Rotators are only interesting where the ray starts blocked; an open one
    // simply leaves and teaches nothing.
    if (request.rotators > 0) {
      final candidates =
          cells
              .where((cell) => !types.containsKey(cell))
              .where((cell) => blockersAtStart[cell]! > 0)
              .toList()
            ..shuffle(random);
      if (candidates.length < request.rotators) return null;
      for (final cell in candidates.take(request.rotators)) {
        types[cell] = ArrowType.rotator;
      }
    }

    return types;
  }

  /// Chooses Stone cells that keep the peel order a valid solution while
  /// making an early slide as costly as possible.
  ///
  /// In peel order a Stone's ray is already clear, so it slides to the edge.
  /// That edge cell must stay off the ray of every arrow peeled after it, and
  /// an earlier Stone's landing cell must stay off its path. Among the cells
  /// that qualify, the best traps are the ones that can be slid right away
  /// into a cell that blocks someone, and whose edge cell lies across the
  /// path of arrows that therefore have to leave first.
  static List<Cell>? _pickStones(
    ForgeRequest request,
    List<Cell> free,
    List<Cell> cells,
    Map<Cell, int> rank,
    Set<Cell> occupied,
    Map<Cell, ArrowDirection> directions,
    Random random,
  ) {
    List<Cell> rayOf(Cell cell) =>
        _ray(cell, directions[cell]!, request.rows, request.columns).toList();
    final rays = {for (final cell in cells) cell: rayOf(cell).toSet()};

    final scored = <(Cell, double)>[];
    for (final cell in free) {
      final path = rayOf(cell);
      if (path.isEmpty) continue;
      final edge = path.last;
      final myRank = rank[cell]!;

      var mustPrecede = 0;
      var unsafe = false;
      for (final other in cells) {
        if (other == cell || !rays[other]!.contains(edge)) continue;
        if (rank[other]! > myRank) {
          unsafe = true;
          break;
        }
        mustPrecede++;
      }
      if (unsafe) continue;

      // Where the Stone lands if the player slides it on move one.
      Cell? early;
      for (final step in path) {
        if (occupied.contains(step)) break;
        early = step;
      }
      final earlyHurts =
          early != null &&
          early != edge &&
          cells.any(
            (other) => other != cell && rays[other]!.contains(early),
          );

      final score =
          mustPrecede + (earlyHurts ? 2.5 : 0) + random.nextDouble() * 0.9;
      scored.add((cell, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    // The edge check above already covers every arrow peeled later, other
    // Stones included, so the best-scoring cells can be taken as they are.
    if (scored.length < request.stones) return null;
    return [for (final (cell, _) in scored.take(request.stones)) cell];
  }

  static List<Cell> _selectCells(ForgeRequest request, Random random) {
    final all = <Cell>[
      for (var row = 0; row < request.rows; row++)
        for (var column = 0; column < request.columns; column++)
          (row: row, column: column),
    ];
    final score = <Cell, double>{
      for (final cell in all)
        cell: _layoutScore(cell, request) + random.nextDouble() * 0.5,
    };
    all.sort((a, b) => score[a]!.compareTo(score[b]!));
    final chosen = all.take(request.arrowCount).toList();
    chosen.shuffle(random);
    return chosen;
  }

  /// Keeps boards looking composed rather than sprinkled: each level id picks
  /// one of a few spatial motifs, and the random jitter breaks the symmetry.
  static double _layoutScore(Cell cell, ForgeRequest request) {
    final centreRow = (request.rows - 1) / 2;
    final centreColumn = (request.columns - 1) / 2;
    final dr = (cell.row - centreRow).abs();
    final dc = (cell.column - centreColumn).abs();
    return switch (request.motif % 6) {
      0 => max(dr, dc) + ((cell.row + cell.column).isEven ? 0.0 : 0.3),
      1 => (dr + dc) * 0.6 + (cell.column.isEven ? 0.0 : 0.25),
      2 => (cell.row - cell.column).abs() * 0.4 + max(dr, dc) * 0.35,
      3 => min(dr, dc) + ((cell.row + cell.column) % 3) * 0.2,
      4 => dc * 0.6 + dr * 0.25 + (cell.row.isEven ? 0.0 : 0.2),
      _ => dr * 0.6 + dc * 0.25 + (cell.column.isEven ? 0.0 : 0.2),
    };
  }

  static Iterable<Cell> _ray(
    Cell cell,
    ArrowDirection direction,
    int rows,
    int columns,
  ) sync* {
    var row = cell.row + direction.rowDelta;
    var column = cell.column + direction.columnDelta;
    while (row >= 0 && row < rows && column >= 0 && column < columns) {
      yield (row: row, column: column);
      row += direction.rowDelta;
      column += direction.columnDelta;
    }
  }

  static Iterable<Cell> _neighbours(Cell cell, int rows, int columns) sync* {
    for (final direction in ArrowDirection.values) {
      final row = cell.row + direction.rowDelta;
      final column = cell.column + direction.columnDelta;
      if (row >= 0 && row < rows && column >= 0 && column < columns) {
        yield (row: row, column: column);
      }
    }
  }

  static ArrowDirection _counterClockwise(ArrowDirection direction) =>
      switch (direction) {
        ArrowDirection.up => ArrowDirection.left,
        ArrowDirection.left => ArrowDirection.down,
        ArrowDirection.down => ArrowDirection.right,
        ArrowDirection.right => ArrowDirection.up,
      };
}
