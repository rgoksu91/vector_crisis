import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/game/arrow_chaos_game.dart';
import 'package:vector_crisis/game/models/game_hud_state.dart';

void main() {
  GameHudState failedState(GameHudMessage message) => GameHudState(
    level: 20,
    totalLevels: 300,
    remaining: 4,
    combo: 0,
    moves: 12,
    moveLimit: 12,
    targetMoves: 10,
    twoStarMoves: 11,
    phase: GamePhase.failed,
    message: message,
  );

  testWidgets('rewarded continue can be granted only once per attempt', (
    tester,
  ) async {
    final game = ArrowChaosGame(hapticsEnabled: () => false);
    game.hud.value = failedState(GameHudMessage.moveLimitReached);

    game.grantBonusMoves(3);
    expect(game.hud.value.phase, GamePhase.playing);
    expect(game.hud.value.moveLimit, 3);
    expect(game.hud.value.rewardedContinueUsed, isTrue);

    game.hud.value = game.hud.value.copyWith(
      phase: GamePhase.failed,
      message: GameHudMessage.moveLimitReached,
    );
    game.grantBonusMoves(3);
    expect(game.hud.value.phase, GamePhase.failed);
    expect(game.hud.value.moveLimit, 3);

    await tester.pump(const Duration(seconds: 2));
  });

  test('rewarded continue cannot reopen a jammed board', () {
    final game = ArrowChaosGame(hapticsEnabled: () => false);
    game.hud.value = failedState(GameHudMessage.boardJammed);

    game.grantBonusMoves(3);

    expect(game.hud.value.phase, GamePhase.failed);
    expect(game.hud.value.rewardedContinueUsed, isFalse);
  });
}
