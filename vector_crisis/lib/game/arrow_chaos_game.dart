import 'dart:async' as async;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/arrow_component.dart';
import 'components/board_component.dart';
import 'components/wall_component.dart';
import 'data/levels.dart';
import 'logic/board_rules.dart';
import 'logic/level_solver.dart';
import 'models/arrow_direction.dart';
import 'models/arrow_seed.dart';
import 'models/arrow_type.dart';
import 'models/game_hud_state.dart';
import 'models/level_data.dart';

/// Levels where the in-game hints introduce a mechanic.
abstract final class LevelPlanMarks {
  static const firstStoneLevel = 12;
  static const firstGearLevel = 14;
}

/// Matches the budget tool/generate_levels.dart solves every level within, so
/// a hint from any shipped starting position never needs the greedy fallback.
/// A hint is a single tap, so the worst case (tens of ms on desktop) is fine.
const _hintStateBudget = 150000;

bool _isJammed(LevelData position) {
  final analysis = LevelSolver.analyze(
    position,
    maxVisitedStates: _hintStateBudget,
  );
  return !analysis.isSolvable && !analysis.hitStateLimit;
}

class ArrowChaosGame extends FlameGame {
  static const freeHintsPerAttempt = 2;
  static const rewardedHintAmount = 2;

  final int initialLevelIndex;
  final bool Function() hapticsEnabled;
  final void Function(int level, int moves)? onLevelCompleted;

  ArrowChaosGame({
    this.initialLevelIndex = 0,
    required this.hapticsEnabled,
    this.onLevelCompleted,
  });

  final ValueNotifier<GameHudState> hud = ValueNotifier<GameHudState>(
    GameHudState.initial(),
  );

  final List<ArrowComponent> _arrows = [];
  final Set<BoardCell> _walls = {};
  bool _hasStones = false;

  /// Bumped on every (re)load so late background results can be discarded.
  int _attempt = 0;

  PositionComponent? _levelRoot;
  late LevelData _currentLevel;
  int _currentLevelIndex = 0;
  int _combo = 0;
  int _moves = 0;
  int? _moveLimit;
  bool _rewardedContinueUsed = false;
  int _hintsRemaining = freeHintsPerAttempt;
  bool _rewardedHintUsed = false;
  double _cellSize = 64;
  Vector2 _boardOrigin = Vector2.zero();
  bool _levelLocked = false;
  bool _actionInProgress = false;
  async.Timer? _messageTimer;

  @override
  Color backgroundColor() => const Color(0xFF0D1020);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadLevel(initialLevelIndex.clamp(0, levels.length - 1));
  }

  /// Every counted move turns all Gears one quarter clockwise, which is what
  /// makes the order of moves decide how many are needed.
  void _spendMove({ArrowComponent? leaving}) {
    _moves++;
    for (final arrow in _arrows) {
      if (arrow.type == ArrowType.gear && arrow != leaving && !arrow.isMoving) {
        arrow.rotateClockwise();
      }
    }
  }

  /// Spends a move on nothing to bring the Gears round. Tapping something
  /// blocked does the same thing; this is the honest button for it.
  void waitOneMove() {
    if (_levelLocked || _actionInProgress || !_gearsOnBoard) return;
    _combo = 0;
    _spendMove();
    _haptic(HapticFeedback.selectionClick);
    _setMessage(GameHudMessage.waited);
    _publishHud();
    _scheduleJamCheck();
    _checkMoveLimit();
  }

  bool get _gearsOnBoard =>
      _arrows.any((arrow) => arrow.type == ArrowType.gear && !arrow.isMoving);

  void onArrowTapped(ArrowComponent arrow) {
    if (_levelLocked || _actionInProgress || arrow.isMoving) return;

    if (arrow.frozen) {
      _combo = 0;
      _spendMove();
      arrow.playBlocked();
      _haptic(HapticFeedback.heavyImpact);
      _setMessage(GameHudMessage.frozenArrowBlocked);
      _publishHud();
      _checkMoveLimit();
      return;
    }

    final isStone = arrow.type == ArrowType.stone;
    final slide = isStone ? _slideSteps(arrow) : 0;
    final clear = isStone ? slide > 0 : canExit(arrow);

    if (arrow.type == ArrowType.rotator && !clear) {
      _combo = 0;
      _spendMove();
      arrow.rotateClockwise();
      _haptic(HapticFeedback.selectionClick);
      _setMessage(GameHudMessage.rotatorTurned);
      _publishHud();
      _scheduleJamCheck();
      _checkMoveLimit();
      return;
    }

    if (!clear) {
      _combo = 0;
      _spendMove();
      arrow.playBlocked();
      _haptic(HapticFeedback.mediumImpact);
      _setMessage(GameHudMessage.pathBlocked);
      _publishHud();
      _checkMoveLimit();
      return;
    }

    if (isStone) {
      _combo = 0;
      _spendMove(leaving: arrow);
      _haptic(HapticFeedback.mediumImpact);
      _setMessage(GameHudMessage.none);
      _slideStone(arrow, slide);
      _publishHud();
      return;
    }

    _combo++;
    _spendMove(leaving: arrow);
    _haptic(HapticFeedback.lightImpact);
    _setMessage(
      _combo >= 3 ? GameHudMessage.combo : GameHudMessage.none,
      _combo,
    );
    _launchArrow(arrow);
    _publishHud();
  }

  bool canExit(ArrowComponent selected) {
    return BoardRules.isPathClear(
      row: selected.row,
      column: selected.column,
      direction: selected.direction,
      rows: _currentLevel.rows,
      columns: _currentLevel.columns,
      occupiedCells: _occupiedExcept(selected),
    );
  }

  Iterable<BoardCell> _occupiedExcept(ArrowComponent selected) => _arrows
      .where((arrow) => arrow != selected && !arrow.isMoving)
      .map<BoardCell>((arrow) => (row: arrow.row, column: arrow.column))
      .followedBy(_walls);

  /// Cells a Stone would travel before hitting an arrow, a wall or the edge.
  int _slideSteps(ArrowComponent stone) {
    final occupied = _occupiedExcept(stone).toSet();
    var steps = 0;
    var row = stone.row + stone.direction.rowDelta;
    var column = stone.column + stone.direction.columnDelta;
    while (BoardRules.isInside(
          row,
          column,
          _currentLevel.rows,
          _currentLevel.columns,
        ) &&
        !occupied.contains((row: row, column: column))) {
      steps++;
      row += stone.direction.rowDelta;
      column += stone.direction.columnDelta;
    }
    return steps;
  }

  void showHint() {
    if (_levelLocked || _actionInProgress || _hintsRemaining <= 0) return;

    // The first exitable arrow is exactly how an unplanned player loses, so
    // the hint follows the solver from the current position instead.
    final plan = _solverHint();
    if (plan != null && plan.$2 == SolverActionType.wait) {
      _hintsRemaining--;
      _haptic(HapticFeedback.selectionClick);
      _setMessage(GameHudMessage.hintWait);
      hud.value = hud.value.copyWith(hintsRemaining: _hintsRemaining);
      return;
    }

    final candidate = plan?.$1 ?? _greedyHint();

    if (candidate == null) {
      _setMessage(GameHudMessage.noAvailableMove);
      return;
    }

    candidate.playHint();
    _hintsRemaining--;
    _haptic(HapticFeedback.selectionClick);
    _setMessage(
      candidate.type == ArrowType.rotator && !canExit(candidate)
          ? GameHudMessage.hintRotate
          : GameHudMessage.hintMarked,
    );
    hud.value = hud.value.copyWith(hintsRemaining: _hintsRemaining);
  }

  void grantBonusHints(int amount) {
    if (hud.value.phase != GamePhase.playing ||
        amount <= 0 ||
        _hintsRemaining > 0 ||
        _rewardedHintUsed) {
      return;
    }
    _rewardedHintUsed = true;
    _hintsRemaining = amount;
    hud.value = hud.value.copyWith(
      hintsRemaining: _hintsRemaining,
      rewardedHintUsed: true,
    );
  }

  (ArrowComponent?, SolverActionType)? _solverHint() {
    final pieces = _pieces();
    if (pieces.isEmpty) return null;
    final solution = LevelSolver.analyze(
      _snapshot(pieces),
      maxVisitedStates: _hintStateBudget,
    ).solution;
    if (solution == null || solution.isEmpty) return null;
    final next = solution.first;
    if (next.type == SolverActionType.wait) return (null, next.type);
    return (pieces[next.arrowId], next.type);
  }

  List<ArrowComponent> _pieces() =>
      _arrows.where((arrow) => !arrow.isMoving).toList();

  /// The live position as a level the solver can read. A thawed Frozen arrow
  /// behaves exactly like a normal one, a Rotator's turns are carried by its
  /// current direction, and landed Stones become fixed walls.
  LevelData _snapshot(List<ArrowComponent> pieces) => LevelData(
    id: _currentLevel.id,
    rows: _currentLevel.rows,
    columns: _currentLevel.columns,
    walls: _walls.toList(),
    arrows: [
      for (final arrow in pieces)
        ArrowSeed(
          row: arrow.row,
          column: arrow.column,
          direction: arrow.direction,
          type: arrow.type == ArrowType.frozen && !arrow.frozen
              ? ArrowType.normal
              : arrow.type,
        ),
    ],
  );

  ArrowComponent? _greedyHint() {
    ArrowComponent? candidate;
    for (final arrow in _arrows) {
      if (!arrow.isMoving && !arrow.frozen && canExit(arrow)) {
        candidate = arrow;
        break;
      }
    }

    if (candidate == null) {
      for (final arrow in _arrows) {
        if (!arrow.isMoving &&
            !arrow.frozen &&
            arrow.type == ArrowType.rotator) {
          candidate = arrow;
          break;
        }
      }
    }
    return candidate;
  }

  void restartLevel() {
    _loadLevel(_currentLevelIndex);
  }

  void grantBonusMoves(int amount) {
    if (hud.value.phase != GamePhase.failed || amount <= 0) return;
    // Extra moves cannot unjam a board; only a restart can.
    if (hud.value.message == GameHudMessage.boardJammed) return;
    if (_rewardedContinueUsed) return;
    _rewardedContinueUsed = true;
    _moveLimit = (_moveLimit ?? _moves) + amount;
    _levelLocked = false;
    _combo = 0;
    hud.value = hud.value.copyWith(
      phase: GamePhase.playing,
      moveLimit: _moveLimit,
      rewardedContinueUsed: true,
      message: GameHudMessage.none,
    );
    _setMessage(GameHudMessage.bonusMoves, amount);
  }

  void nextLevel() {
    if (_currentLevelIndex >= levels.length - 1) {
      _loadLevel(0);
      return;
    }
    _loadLevel(_currentLevelIndex + 1);
  }

  void previousLevel() {
    if (_currentLevelIndex == 0) return;
    _loadLevel(_currentLevelIndex - 1);
  }

  void _loadLevel(int index) {
    _messageTimer?.cancel();
    _currentLevelIndex = index;
    _currentLevel = levels[index];
    _combo = 0;
    _moves = 0;
    _moveLimit = _currentLevel.moveLimit;
    _rewardedContinueUsed = false;
    _hintsRemaining = freeHintsPerAttempt;
    _rewardedHintUsed = false;
    _levelLocked = false;
    _actionInProgress = false;
    _arrows.clear();
    _walls.clear();
    _attempt++;
    _hasStones = _currentLevel.arrows.any(
      (arrow) => arrow.type == ArrowType.stone,
    );

    _levelRoot?.removeFromParent();

    final availableWidth = math.max(220.0, size.x - 32);
    final availableHeight = math.max(260.0, size.y - 220);
    _cellSize = math
        .min(
          82.0,
          math.min(
            availableWidth / _currentLevel.columns,
            availableHeight / _currentLevel.rows,
          ),
        )
        .toDouble();

    final boardWidth = _currentLevel.columns * _cellSize;
    final boardHeight = _currentLevel.rows * _cellSize;
    _boardOrigin = Vector2(
      (size.x - boardWidth) / 2,
      128 + (availableHeight - boardHeight) / 2,
    );

    final root = PositionComponent(position: _boardOrigin, priority: 1);
    _levelRoot = root;
    add(root);

    root.add(
      BoardComponent(
        rows: _currentLevel.rows,
        columns: _currentLevel.columns,
        cellSize: _cellSize,
      ),
    );

    for (var i = 0; i < _currentLevel.arrows.length; i++) {
      final arrow = ArrowComponent(
        arrowId: i,
        seed: _currentLevel.arrows[i],
        cellSize: _cellSize,
      );
      _arrows.add(arrow);
      root.add(arrow);
    }

    hud.value = GameHudState(
      level: _currentLevel.id,
      totalLevels: levels.length,
      remaining: _arrows.length,
      combo: 0,
      moves: 0,
      moveLimit: _moveLimit,
      targetMoves: _currentLevel.targetMoves,
      twoStarMoves: _currentLevel.twoStarMoves,
      rewardedContinueUsed: false,
      hintsRemaining: _hintsRemaining,
      rewardedHintUsed: false,
      phase: GamePhase.playing,
      gearsOnBoard: _gearsOnBoard,
      message: _levelIntroMessage(_currentLevel.id),
    );
  }

  void _launchArrow(ArrowComponent arrow) {
    _actionInProgress = true;
    final originalRow = arrow.row;
    final originalColumn = arrow.column;
    final target = _exitTarget(arrow);

    arrow.startFlight(target, () {
      if (arrow.type == ArrowType.bomb) {
        _resolveBomb(arrow, originalRow, originalColumn);
        return;
      }

      _arrows.remove(arrow);
      arrow.removeFromParent();
      _thawFrozenNear({(originalRow, originalColumn)});
      _actionInProgress = false;
      _publishHud();
      _scheduleJamCheck();
      _checkLevelCompletedOrFailed();
    });
  }

  void _slideStone(ArrowComponent stone, int steps) {
    _actionInProgress = true;
    final originalRow = stone.row;
    final originalColumn = stone.column;
    final wallRow = stone.row + stone.direction.rowDelta * steps;
    final wallColumn = stone.column + stone.direction.columnDelta * steps;
    final target = Vector2(wallColumn * _cellSize, wallRow * _cellSize);

    stone.startFlight(target, () {
      _arrows.remove(stone);
      stone.removeFromParent();
      _walls.add((row: wallRow, column: wallColumn));
      _levelRoot?.add(
        WallComponent(row: wallRow, column: wallColumn, cellSize: _cellSize),
      );
      _haptic(HapticFeedback.heavyImpact);
      _thawFrozenNear({(originalRow, originalColumn)});
      _actionInProgress = false;
      _publishHud();
      _scheduleJamCheck();
      _checkLevelCompletedOrFailed();
    });
  }

  /// Stones are the only thing that can make a board unsolvable, so on a
  /// level that has them the position is checked after every move and the
  /// run ends as soon as it is lost, instead of letting the player burn the
  /// rest of the move budget. The search runs off the UI thread; a jam is
  /// permanent, so a result that arrives a few taps late is still true as
  /// long as the same attempt is running.
  void _scheduleJamCheck() {
    if (!_hasStones || _levelLocked || _arrows.isEmpty) return;
    final attempt = _attempt;
    compute(_isJammed, _snapshot(_pieces())).then((jammed) {
      if (!jammed || attempt != _attempt || _levelLocked) return;
      if (_arrows.isEmpty) return;
      _levelLocked = true;
      _combo = 0;
      _haptic(HapticFeedback.heavyImpact);
      hud.value = hud.value.copyWith(
        combo: 0,
        moves: _moves,
        phase: GamePhase.failed,
        message: GameHudMessage.boardJammed,
      );
    });
  }

  void _resolveBomb(ArrowComponent bomb, int originalRow, int originalColumn) {
    final victims = _arrows
        .where(
          (arrow) =>
              arrow != bomb &&
              !arrow.isMoving &&
              arrow.type != ArrowType.stone &&
              _isAdjacent(originalRow, originalColumn, arrow.row, arrow.column),
        )
        .toList(growable: false);

    final removedCells = <(int, int)>{(originalRow, originalColumn)};
    _arrows.remove(bomb);
    bomb.removeFromParent();

    for (final victim in victims) {
      removedCells.add((victim.row, victim.column));
      _arrows.remove(victim);
      victim.startExplosion(victim.removeFromParent);
    }

    _haptic(HapticFeedback.heavyImpact);
    _setMessage(GameHudMessage.bomb, victims.length);
    _thawFrozenNear(removedCells);
    _actionInProgress = false;
    _publishHud();
    _scheduleJamCheck();

    Future<void>.delayed(
      const Duration(milliseconds: 240),
      _checkLevelCompletedOrFailed,
    );
  }

  void _thawFrozenNear(Set<(int, int)> removedCells) {
    for (final arrow in _arrows) {
      if (!arrow.frozen) continue;
      final shouldThaw = removedCells.any(
        (cell) => _isAdjacent(arrow.row, arrow.column, cell.$1, cell.$2),
      );
      if (shouldThaw) arrow.thaw();
    }
  }

  Vector2 _exitTarget(ArrowComponent arrow) {
    final relativeRight = size.x - _boardOrigin.x + _cellSize * 2;
    final relativeBottom = size.y - _boardOrigin.y + _cellSize * 2;
    final relativeLeft = -_boardOrigin.x - _cellSize * 2;
    final relativeTop = -_boardOrigin.y - _cellSize * 2;

    return switch (arrow.direction) {
      ArrowDirection.right => Vector2(relativeRight, arrow.position.y),
      ArrowDirection.left => Vector2(relativeLeft, arrow.position.y),
      ArrowDirection.down => Vector2(arrow.position.x, relativeBottom),
      ArrowDirection.up => Vector2(arrow.position.x, relativeTop),
    };
  }

  void _checkLevelCompletedOrFailed() {
    if (_actionInProgress) return;
    if (_arrows.isNotEmpty) {
      _checkMoveLimit();
      return;
    }
    if (_levelLocked) return;

    _levelLocked = true;
    _haptic(HapticFeedback.heavyImpact);
    final allDone = _currentLevelIndex == levels.length - 1;
    hud.value = hud.value.copyWith(
      remaining: 0,
      phase: allDone ? GamePhase.allLevelsCompleted : GamePhase.won,
      message: allDone
          ? GameHudMessage.campaignCompleted
          : GameHudMessage.boardClear,
    );
    onLevelCompleted?.call(_currentLevel.id, _moves);
  }

  void _checkMoveLimit() {
    final limit = _moveLimit;
    if (limit == null || _moves < limit || _arrows.isEmpty || _levelLocked) {
      return;
    }

    _levelLocked = true;
    _actionInProgress = false;
    _combo = 0;
    _haptic(HapticFeedback.heavyImpact);
    hud.value = hud.value.copyWith(
      combo: 0,
      moves: _moves,
      phase: GamePhase.failed,
      message: GameHudMessage.moveLimitReached,
    );
  }

  void _publishHud() {
    hud.value = hud.value.copyWith(
      gearsOnBoard: _gearsOnBoard,
      remaining: _arrows.where((arrow) => !arrow.isMoving).length,
      combo: _combo,
      moves: _moves,
    );
  }

  void _setMessage(GameHudMessage message, [int value = 0]) {
    _messageTimer?.cancel();
    hud.value = hud.value.copyWith(message: message, messageValue: value);
    if (message == GameHudMessage.none) return;

    _messageTimer = async.Timer(const Duration(milliseconds: 1300), () {
      if (hud.value.phase == GamePhase.playing) {
        hud.value = hud.value.copyWith(
          message: GameHudMessage.none,
          messageValue: 0,
        );
      }
    });
  }

  bool _isAdjacent(int r1, int c1, int r2, int c2) =>
      BoardRules.areAdjacent(r1, c1, r2, c2);

  void _haptic(Future<void> Function() feedback) {
    if (hapticsEnabled()) feedback();
  }

  GameHudMessage _levelIntroMessage(int level) => switch (level) {
    1 => GameHudMessage.introTapArrow,
    6 => GameHudMessage.introRotator,
    8 => GameHudMessage.introFrozen,
    10 => GameHudMessage.introBomb,
    LevelPlanMarks.firstStoneLevel => GameHudMessage.introStone,
    LevelPlanMarks.firstGearLevel => GameHudMessage.introGear,
    16 => GameHudMessage.introRotatorClockwise,
    _ => GameHudMessage.none,
  };

  @override
  void onRemove() {
    _messageTimer?.cancel();
    hud.dispose();
    super.onRemove();
  }
}
