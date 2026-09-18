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
  hintWait,
  bonusMoves,
  bomb,
  campaignCompleted,
  boardClear,
  moveLimitReached,
  boardJammed,
  waited,
  introTapArrow,
  introRotator,
  introFrozen,
  introBomb,
  introRotatorClockwise,
  introStone,
  introGear,
}

@immutable
class GameHudState {
  final int level;
  final int totalLevels;
  final int remaining;
  final int combo;
  final int moves;
  final int? moveLimit;
  final int? targetMoves;
  final int? twoStarMoves;
  final bool rewardedContinueUsed;
  final int hintsRemaining;
  final bool rewardedHintUsed;
  final GamePhase phase;
  final GameHudMessage message;
  final int messageValue;

  /// A Gear is still on the board, so spending a move to turn them all is a
  /// real option and the wait button is shown.
  final bool gearsOnBoard;

  const GameHudState({
    required this.level,
    required this.totalLevels,
    required this.remaining,
    required this.combo,
    required this.moves,
    required this.moveLimit,
    this.targetMoves,
    this.twoStarMoves,
    this.rewardedContinueUsed = false,
    this.hintsRemaining = 0,
    this.rewardedHintUsed = false,
    required this.phase,
    required this.message,
    this.messageValue = 0,
    this.gearsOnBoard = false,
  });

  factory GameHudState.initial() => const GameHudState(
    level: 1,
    totalLevels: 1,
    remaining: 0,
    combo: 0,
    moves: 0,
    moveLimit: null,
    targetMoves: null,
    twoStarMoves: null,
    hintsRemaining: 0,
    phase: GamePhase.playing,
    message: GameHudMessage.none,
  );

  GameHudState copyWith({
    bool? gearsOnBoard,
    int? level,
    int? totalLevels,
    int? remaining,
    int? combo,
    int? moves,
    int? moveLimit,
    int? targetMoves,
    int? twoStarMoves,
    bool? rewardedContinueUsed,
    int? hintsRemaining,
    bool? rewardedHintUsed,
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
      targetMoves: targetMoves ?? this.targetMoves,
      twoStarMoves: twoStarMoves ?? this.twoStarMoves,
      rewardedContinueUsed: rewardedContinueUsed ?? this.rewardedContinueUsed,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      rewardedHintUsed: rewardedHintUsed ?? this.rewardedHintUsed,
      phase: phase ?? this.phase,
      message: message ?? this.message,
      messageValue: messageValue ?? this.messageValue,
      gearsOnBoard: gearsOnBoard ?? this.gearsOnBoard,
    );
  }
}
