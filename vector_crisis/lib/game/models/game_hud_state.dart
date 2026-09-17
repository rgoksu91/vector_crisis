import 'package:flutter/foundation.dart';

enum GamePhase { playing, won, failed, allLevelsCompleted }

enum GameHudMessage {
  none,
  frozenArrowBlocked,
  rotatorTurned,
  pathBlocked,
  combo,
  noAvailableMove,
  hintRotate,
  hintMarked,
  bonusMoves,
  bomb,
  campaignCompleted,
  boardClear,
  moveLimitReached,
  boardJammed,
  introTapArrow,
  introRotator,
  introFrozen,
  introBomb,
  introRotatorClockwise,
  introStone,
}

@immutable
class GameHudState {
  final int level;
  final int totalLevels;
  final int remaining;
  final int combo;
  final int moves;
  final int? moveLimit;
  final GamePhase phase;
  final GameHudMessage message;
  final int messageValue;

  const GameHudState({
    required this.level,
    required this.totalLevels,
    required this.remaining,
    required this.combo,
    required this.moves,
    required this.moveLimit,
    required this.phase,
    required this.message,
    this.messageValue = 0,
  });

  factory GameHudState.initial() => const GameHudState(
    level: 1,
    totalLevels: 1,
    remaining: 0,
    combo: 0,
    moves: 0,
    moveLimit: null,
    phase: GamePhase.playing,
    message: GameHudMessage.none,
  );

  GameHudState copyWith({
    int? level,
    int? totalLevels,
    int? remaining,
    int? combo,
    int? moves,
    int? moveLimit,
    GamePhase? phase,
    GameHudMessage? message,
    int? messageValue,
  }) {
    return GameHudState(
      level: level ?? this.level,
      totalLevels: totalLevels ?? this.totalLevels,
      remaining: remaining ?? this.remaining,
      combo: combo ?? this.combo,
      moves: moves ?? this.moves,
      moveLimit: moveLimit ?? this.moveLimit,
      phase: phase ?? this.phase,
      message: message ?? this.message,
      messageValue: messageValue ?? this.messageValue,
    );
  }
}
