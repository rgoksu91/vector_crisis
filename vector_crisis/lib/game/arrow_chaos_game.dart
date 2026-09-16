import 'dart:async' as async;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/arrow_component.dart';
import 'components/board_component.dart';
import 'data/levels.dart';
import 'logic/board_rules.dart';
import 'models/arrow_direction.dart';
import 'models/arrow_type.dart';
import 'models/game_hud_state.dart';
import 'models/level_data.dart';

class ArrowChaosGame extends FlameGame {
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

  PositionComponent? _levelRoot;
  late LevelData _currentLevel;
  int _currentLevelIndex = 0;
  int _combo = 0;
  int _moves = 0;
  int? _moveLimit;
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

  void onArrowTapped(ArrowComponent arrow) {
    if (_levelLocked || _actionInProgress || arrow.isMoving) return;

    if (arrow.frozen) {
      _combo = 0;
      _moves++;
      arrow.playBlocked();
      _haptic(HapticFeedback.heavyImpact);
      _setMessage('Buzlu ok: yanındaki bir oku çıkar.');
      _publishHud();
      _checkMoveLimit();
      return;
    }

    final clear = canExit(arrow);

    if (arrow.type == ArrowType.rotator && !clear) {
      _combo = 0;
      _moves++;
      arrow.rotateClockwise();
      _haptic(HapticFeedback.selectionClick);
      _setMessage('Rotator 90° döndü.');
      _publishHud();
      _checkMoveLimit();
      return;
    }

    if (!clear) {
      _combo = 0;
      _moves++;
      arrow.playBlocked();
      _haptic(HapticFeedback.mediumImpact);
      _setMessage('Önü kapalı.');
      _publishHud();
      _checkMoveLimit();
      return;
    }

    _combo++;
    _moves++;
    _haptic(HapticFeedback.lightImpact);
    _setMessage(_combo >= 3 ? 'Combo x$_combo' : '');
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
      occupiedCells: _arrows
          .where((arrow) => arrow != selected && !arrow.isMoving)
          .map((arrow) => (row: arrow.row, column: arrow.column)),
    );
  }

  void showHint() {
    if (_levelLocked) return;

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

    if (candidate == null) {
      _setMessage('Şu an kullanılabilir hamle yok.');
      return;
    }

    candidate.playHint();
    _haptic(HapticFeedback.selectionClick);
    _setMessage(
      candidate.type == ArrowType.rotator && !canExit(candidate)
          ? 'İpucu: turuncu oku döndür.'
          : 'İpucu işaretlendi.',
    );
  }

  void restartLevel() {
    _loadLevel(_currentLevelIndex);
  }

  void grantBonusMoves(int amount) {
    if (hud.value.phase != GamePhase.failed || amount <= 0) return;
    _moveLimit = (_moveLimit ?? _moves) + amount;
    _levelLocked = false;
    _combo = 0;
    hud.value = hud.value.copyWith(
      phase: GamePhase.playing,
      moveLimit: _moveLimit,
      message: '+$amount hamle kazandın!',
    );
    _setMessage('+$amount hamle kazandın!');
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
    _levelLocked = false;
    _actionInProgress = false;
    _arrows.clear();

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
      phase: GamePhase.playing,
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
      _checkLevelCompletedOrFailed();
    });
  }

  void _resolveBomb(ArrowComponent bomb, int originalRow, int originalColumn) {
    final victims = _arrows
        .where(
          (arrow) =>
              arrow != bomb &&
              !arrow.isMoving &&
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
    _setMessage(victims.isEmpty ? 'BOOM!' : 'BOOM! +${victims.length}');
    _thawFrozenNear(removedCells);
    _actionInProgress = false;
    _publishHud();

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
      message: allDone ? 'MVP tamamlandı!' : 'Board clear!',
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
      message: 'Hamle sınırı doldu.',
    );
  }

  void _publishHud() {
    hud.value = hud.value.copyWith(
      remaining: _arrows.where((arrow) => !arrow.isMoving).length,
      combo: _combo,
      moves: _moves,
    );
  }

  void _setMessage(String message) {
    _messageTimer?.cancel();
    hud.value = hud.value.copyWith(message: message);
    if (message.isEmpty) return;

    _messageTimer = async.Timer(const Duration(milliseconds: 1300), () {
      if (hud.value.phase == GamePhase.playing) {
        hud.value = hud.value.copyWith(message: '');
      }
    });
  }

  bool _isAdjacent(int r1, int c1, int r2, int c2) =>
      BoardRules.areAdjacent(r1, c1, r2, c2);

  void _haptic(Future<void> Function() feedback) {
    if (hapticsEnabled()) feedback();
  }

  String _levelIntroMessage(int level) => switch (level) {
    1 => 'Oka dokun ve board dışına çıkar.',
    6 => 'Turuncu: önü kapalıysa 90° döner.',
    8 => 'Buzlu ok: komşu ok çıkınca çözülür.',
    10 => 'Kırmızı bomba: komşuları patlatır.',
    16 => 'Turuncu ok önü kapalıyken saat yönünde döner.',
    _ => '',
  };

  @override
  void onRemove() {
    _messageTimer?.cancel();
    hud.dispose();
    super.onRemove();
  }
}
