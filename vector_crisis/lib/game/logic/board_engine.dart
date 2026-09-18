import 'board_rules.dart';
import '../models/arrow_direction.dart';
import '../models/arrow_type.dart';
import '../models/level_data.dart';

/// Bitmask model of a board, shared by the solver and the difficulty probes.
///
/// Arrows never change cell, so a position is described by the mask of
/// arrows still on the board plus an auxiliary word: two bits of accumulated
/// clockwise turn per Rotator, then three bits per Stone recording how far it
/// slid before it became a wall. A state key packs both as
/// `alive | aux << arrowCount`.
///
/// Stones are what make the game non-monotone: a wall that lands on another
/// arrow's only way out can jam the board for good. Gears add the other half:
/// every Gear turns a quarter clockwise after every move, so which way one
/// points depends on how many moves have been played, and the order of moves
/// decides how many are needed.
class BoardEngine {
  /// Beyond this many arrows a state no longer fits in one integer key.
  static const maxArrows = 44;
  static const maxStateBits = 62;
  static const _landBits = 3;
  static const _maxPath = 1 << _landBits;

  final int arrowCount;
  final int allMask;
  final int rotatorCount;
  final int stoneCount;
  final int gearCount;
  final List<int> _rayMask;
  final List<bool> _wallBlocked;
  final List<int> _neighbourMask;
  final List<int> _baseDirection;
  final List<ArrowType> _types;
  final List<int> _rotatorSlot;
  final List<int> _stoneSlot;
  final int _frozenMask;
  final int _bombMask;
  final int _stoneMask;
  final int _gearMask;

  /// Per Stone: cells on its path in order, as the arrow standing there (or
  /// -1), whether a fixed wall stands there, and the path length.
  final List<int> _pathArrow;
  final List<int> _pathWall;
  final List<int> _pathLength;

  /// `[(arrow * 4 + direction) * stoneCount + stone]`: bit k is set when that
  /// Stone, landed at path step k, sits on the arrow's ray.
  final List<int> _landBlocks;

  /// `[(stone * stoneCount + other) * 8 + k]`: the step on the stone's path
  /// where the other Stone landed at step k now stands, or -1.
  final List<int> _landOnPath;

  BoardEngine._(
    this.arrowCount,
    this.allMask,
    this.rotatorCount,
    this.stoneCount,
    this.gearCount,
    this._rayMask,
    this._wallBlocked,
    this._neighbourMask,
    this._baseDirection,
    this._types,
    this._rotatorSlot,
    this._stoneSlot,
    this._frozenMask,
    this._bombMask,
    this._stoneMask,
    this._gearMask,
    this._pathArrow,
    this._pathWall,
    this._pathLength,
    this._landBlocks,
    this._landOnPath,
  );

  factory BoardEngine(LevelData level) {
    final arrows = level.arrows;
    final count = arrows.length;
    final rows = level.rows;
    final columns = level.columns;
    if (count > maxArrows) {
      throw ArgumentError(
        'Level ${level.id} has $count arrows; at most $maxArrows are supported.',
      );
    }
    if (rows > _maxPath + 1 || columns > _maxPath + 1) {
      throw ArgumentError('Level ${level.id} is too large for Stone paths.');
    }

    int cellOf(int row, int column) => row * columns + column;
    final indexByCell = <int, int>{
      for (var i = 0; i < count; i++)
        cellOf(arrows[i].row, arrows[i].column): i,
    };
    final walls = {for (final w in level.walls) cellOf(w.row, w.column)};

    List<int> rayCells(int row, int column, ArrowDirection direction) {
      final cells = <int>[];
      var r = row + direction.rowDelta;
      var c = column + direction.columnDelta;
      while (BoardRules.isInside(r, c, rows, columns)) {
        cells.add(cellOf(r, c));
        r += direction.rowDelta;
        c += direction.columnDelta;
      }
      return cells;
    }

    final rayMask = List<int>.filled(count * 4, 0);
    final wallBlocked = List<bool>.filled(count * 4, false);
    final rays = List<List<int>>.filled(count * 4, const []);
    final neighbourMask = List<int>.filled(count, 0);
    final baseDirection = List<int>.filled(count, 0);
    final rotatorSlot = List<int>.filled(count, -1);
    final stoneSlot = List<int>.filled(count, -1);
    final stoneArrow = <int>[];
    final types = <ArrowType>[];
    var frozenMask = 0;
    var bombMask = 0;
    var stoneMask = 0;
    var gearMask = 0;
    var rotators = 0;
    var gears = 0;

    for (var i = 0; i < count; i++) {
      final arrow = arrows[i];
      baseDirection[i] = arrow.direction.index;
      types.add(arrow.type);
      switch (arrow.type) {
        case ArrowType.frozen:
          frozenMask |= 1 << i;
        case ArrowType.bomb:
          bombMask |= 1 << i;
        case ArrowType.rotator:
          rotatorSlot[i] = rotators++;
        case ArrowType.stone:
          stoneMask |= 1 << i;
          stoneSlot[i] = stoneArrow.length;
          stoneArrow.add(i);
        case ArrowType.gear:
          gearMask |= 1 << i;
          gears++;
        case ArrowType.normal:
          break;
      }

      for (final direction in ArrowDirection.values) {
        final index = i * 4 + direction.index;
        final cells = rayCells(arrow.row, arrow.column, direction);
        rays[index] = cells;
        var mask = 0;
        for (final cell in cells) {
          final other = indexByCell[cell];
          if (other != null) mask |= 1 << other;
          if (walls.contains(cell)) wallBlocked[index] = true;
        }
        rayMask[index] = mask;

        final nearRow = arrow.row + direction.rowDelta;
        final nearColumn = arrow.column + direction.columnDelta;
        if (BoardRules.isInside(nearRow, nearColumn, rows, columns)) {
          final neighbour = indexByCell[cellOf(nearRow, nearColumn)];
          if (neighbour != null) neighbourMask[i] |= 1 << neighbour;
        }
      }
    }

    final stones = stoneArrow.length;
    final stateBits =
        count + rotators * 2 + stones * _landBits + (gears > 0 ? 2 : 0);
    if (stateBits > maxStateBits) {
      throw ArgumentError(
        'Level ${level.id} needs $stateBits state bits; at most '
        '$maxStateBits fit in a key.',
      );
    }

    final paths = [
      for (final arrow in stoneArrow) rays[arrow * 4 + baseDirection[arrow]],
    ];
    final pathArrow = List<int>.filled(stones * _maxPath, -1);
    final pathWall = List<int>.filled(stones, 0);
    final pathLength = List<int>.filled(stones, 0);
    for (var s = 0; s < stones; s++) {
      pathLength[s] = paths[s].length;
      for (var step = 0; step < paths[s].length; step++) {
        final cell = paths[s][step];
        pathArrow[s * _maxPath + step] = indexByCell[cell] ?? -1;
        if (walls.contains(cell)) pathWall[s] |= 1 << step;
      }
    }

    final landBlocks = List<int>.filled(count * 4 * stones, 0);
    for (var index = 0; index < count * 4; index++) {
      final ray = rays[index].toSet();
      for (var s = 0; s < stones; s++) {
        var bits = 0;
        for (var step = 0; step < paths[s].length; step++) {
          if (ray.contains(paths[s][step])) bits |= 1 << step;
        }
        landBlocks[index * stones + s] = bits;
      }
    }

    final landOnPath = List<int>.filled(stones * stones * _maxPath, -1);
    for (var s = 0; s < stones; s++) {
      for (var other = 0; other < stones; other++) {
        if (other == s) continue;
        for (var k = 0; k < paths[other].length; k++) {
          landOnPath[(s * stones + other) * _maxPath + k] = paths[s].indexOf(
            paths[other][k],
          );
        }
      }
    }

    return BoardEngine._(
      count,
      count == 0 ? 0 : (1 << count) - 1,
      rotators,
      stones,
      gears,
      rayMask,
      wallBlocked,
      neighbourMask,
      baseDirection,
      types,
      rotatorSlot,
      stoneSlot,
      frozenMask,
      bombMask,
      stoneMask,
      gearMask,
      pathArrow,
      pathWall,
      pathLength,
      landBlocks,
      landOnPath,
    );
  }

  int get stateBits =>
      arrowCount +
      rotatorCount * 2 +
      stoneCount * _landBits +
      (gearCount > 0 ? 2 : 0);

  int get _gearShift => rotatorCount * 2 + stoneCount * _landBits;

  /// Quarter turns every Gear has taken, which is the move count mod 4.
  int gearPhase(int aux) => gearCount == 0 ? 0 : (aux >> _gearShift) & 3;

  int _advanceGears(int aux) => gearCount == 0
      ? aux
      : (aux & ~(3 << _gearShift)) | (((gearPhase(aux) + 1) & 3) << _gearShift);

  ArrowType typeOf(int arrow) => _types[arrow];

  int directionIndex(int arrow, int aux) {
    if ((_gearMask >> arrow) & 1 != 0) {
      return (_baseDirection[arrow] + gearPhase(aux)) & 3;
    }
    final slot = _rotatorSlot[arrow];
    if (slot < 0) return _baseDirection[arrow];
    return (_baseDirection[arrow] + ((aux >> (slot * 2)) & 3)) & 3;
  }

  /// Spending a move without touching the board, which is what a player does
  /// by tapping something blocked. It is only ever useful to line a Gear up,
  /// so it is offered only while one is still on the board.
  int waitMove(int key) {
    if (gearCount == 0 || (key & allMask & _gearMask) == 0) return -1;
    final aux = key >> arrowCount;
    return (key & allMask) | (_advanceGears(aux) << arrowCount);
  }

  int _landStep(int stoneSlot, int aux) =>
      (aux >> (rotatorCount * 2 + stoneSlot * _landBits)) & (_maxPath - 1);

  /// Whether nothing — arrow, fixed wall or landed Stone — stands on the ray.
  bool isClear(int arrow, int alive, int aux) {
    final index = arrow * 4 + directionIndex(arrow, aux);
    return (alive & _rayMask[index]) == 0 && !_walled(index, alive, aux);
  }

  bool _walled(int index, int alive, int aux) {
    if (_wallBlocked[index]) return true;
    if (stoneCount == 0) return false;

    var landed = _stoneMask & ~alive;
    while (landed != 0) {
      final bit = landed & -landed;
      landed ^= bit;
      final slot = _stoneSlot[bit.bitLength - 1];
      final blocks = _landBlocks[index * stoneCount + slot];
      if (blocks != 0 && (blocks >> _landStep(slot, aux)) & 1 != 0) {
        return true;
      }
    }
    return false;
  }

  /// How many cells a Stone would slide right now; 0 means it cannot move.
  int slideSteps(int stone, int alive, int aux) {
    final slot = _stoneSlot[stone];
    final length = _pathLength[slot];
    final walls = _pathWall[slot];
    var limit = length;
    for (var step = 0; step < length; step++) {
      final standing = _pathArrow[slot * _maxPath + step];
      if ((walls >> step) & 1 != 0 ||
          (standing >= 0 && (alive >> standing) & 1 != 0)) {
        limit = step;
        break;
      }
    }

    // A landed Stone closer than the first arrow stops the slide sooner.
    var landed = _stoneMask & ~alive;
    while (landed != 0) {
      final bit = landed & -landed;
      landed ^= bit;
      final other = _stoneSlot[bit.bitLength - 1];
      final at =
          _landOnPath[(slot * stoneCount + other) * _maxPath +
              _landStep(other, aux)];
      if (at >= 0 && at < limit) limit = at;
    }
    return limit;
  }

  /// A Frozen arrow thaws permanently once any arrow beside it has left.
  bool isFrozen(int arrow, int alive) =>
      (_frozenMask & (1 << arrow)) != 0 &&
      ((allMask & ~alive) & _neighbourMask[arrow]) == 0;

  /// Whether the arrow can leave, or for a Stone, slide all the way out to
  /// the edge — the move a player reads as "its path is open".
  bool canExit(int arrow, int alive, int aux) {
    if (isFrozen(arrow, alive)) return false;
    if (_types[arrow] == ArrowType.stone) {
      final slot = _stoneSlot[arrow];
      return _pathLength[slot] > 0 &&
          slideSteps(arrow, alive, aux) == _pathLength[slot];
    }
    return isClear(arrow, alive, aux);
  }

  /// Whether tapping the arrow changes the position at all.
  bool isPlayable(int arrow, int alive, int aux) {
    if (isFrozen(arrow, alive)) return false;
    return switch (_types[arrow]) {
      ArrowType.rotator => true,
      ArrowType.stone => slideSteps(arrow, alive, aux) > 0,
      _ => isClear(arrow, alive, aux),
    };
  }

  /// The key after tapping [arrow] in [key], or -1 if the tap does nothing.
  int move(int arrow, int key) {
    final alive = key & allMask;
    if (isFrozen(arrow, alive)) return -1;
    var aux = key >> arrowCount;
    final bit = 1 << arrow;

    switch (_types[arrow]) {
      case ArrowType.stone:
        final steps = slideSteps(arrow, alive, aux);
        if (steps == 0) return -1;
        final shift = rotatorCount * 2 + _stoneSlot[arrow] * _landBits;
        aux = (aux & ~((_maxPath - 1) << shift)) | ((steps - 1) << shift);
        return (alive & ~bit) | (_advanceGears(aux) << arrowCount);
      case ArrowType.rotator:
        if (isClear(arrow, alive, aux)) {
          return (alive & ~bit) | (_advanceGears(aux) << arrowCount);
        }
        final shift = _rotatorSlot[arrow] * 2;
        final turned = (((aux >> shift) & 3) + 1) & 3;
        aux = (aux & ~(3 << shift)) | (turned << shift);
        return alive | (_advanceGears(aux) << arrowCount);
      case ArrowType.bomb:
        if (!isClear(arrow, alive, aux)) return -1;
        // Stones are too heavy to blast; only ordinary arrows go with it.
        final blast = _neighbourMask[arrow] & alive & ~_stoneMask;
        return (alive & ~bit & ~blast) | (_advanceGears(aux) << arrowCount);
      case ArrowType.normal:
      case ArrowType.frozen:
      case ArrowType.gear:
        if (!isClear(arrow, alive, aux)) return -1;
        return (alive & ~bit) | (_advanceGears(aux) << arrowCount);
    }
  }

  /// Admissible lower bound on the moves still needed to clear [alive].
  ///
  /// Only a bomb removes an arrow the player never tapped, and never a Stone,
  /// so every other arrow costs at least one move of its own. The bound is
  /// consistent: a single move retires at most one such arrow.
  int movesLowerBound(int alive) {
    var covered = 0;
    var bombs = alive & _bombMask;
    while (bombs != 0) {
      final bit = bombs & -bombs;
      bombs ^= bit;
      covered |= _neighbourMask[bit.bitLength - 1];
    }
    return _popCount(alive & ~(covered & ~_stoneMask));
  }

  static int _popCount(int value) {
    var count = 0;
    var bits = value;
    while (bits != 0) {
      bits &= bits - 1;
      count++;
    }
    return count;
  }

  int playableCount(int alive, int aux) {
    var count = 0;
    var remaining = alive;
    while (remaining != 0) {
      final bit = remaining & -remaining;
      remaining ^= bit;
      if (isPlayable(bit.bitLength - 1, alive, aux)) count++;
    }
    return count;
  }

  int exitableCount(int alive, int aux) {
    var count = 0;
    var remaining = alive;
    while (remaining != 0) {
      final bit = remaining & -remaining;
      remaining ^= bit;
      if (canExit(bit.bitLength - 1, alive, aux)) count++;
    }
    return count;
  }

  /// Collects arrow indices into [into] and returns how many were written.
  int collectPlayable(int alive, int aux, List<int> into) {
    var count = 0;
    var remaining = alive;
    while (remaining != 0) {
      final bit = remaining & -remaining;
      remaining ^= bit;
      final index = bit.bitLength - 1;
      if (isPlayable(index, alive, aux)) into[count++] = index;
    }
    return count;
  }

  int collectExitable(int alive, int aux, List<int> into) {
    var count = 0;
    var remaining = alive;
    while (remaining != 0) {
      final bit = remaining & -remaining;
      remaining ^= bit;
      final index = bit.bitLength - 1;
      if (canExit(index, alive, aux)) into[count++] = index;
    }
    return count;
  }

  /// Whether sliding [stone] now would drop a wall onto the current ray of
  /// another live arrow — the one-move lookahead of a careful player.
  bool slideBlocksSomeone(int stone, int key) {
    final next = move(stone, key);
    if (next < 0) return false;
    final before = key & allMask;
    final after = next & allMask;
    final auxBefore = key >> arrowCount;
    final auxAfter = next >> arrowCount;
    var remaining = after;
    while (remaining != 0) {
      final bit = remaining & -remaining;
      remaining ^= bit;
      final arrow = bit.bitLength - 1;
      final index = arrow * 4 + directionIndex(arrow, auxBefore);
      if (!_walled(index, before, auxBefore) &&
          _walled(index, after, auxAfter)) {
        return true;
      }
    }
    return false;
  }
}
