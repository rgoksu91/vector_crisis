import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/game/arrow_chaos_game.dart';

void main() {
  test('an attempt has two free hints and one rewarded refill', () async {
    final game = ArrowChaosGame(hapticsEnabled: () => false);
    game.onGameResize(Vector2(400, 800));
    await game.onLoad();

    expect(game.hud.value.hintsRemaining, 2);

    game.showHint();
    game.showHint();
    game.showHint();
    expect(game.hud.value.hintsRemaining, 0);

    game.grantBonusHints(ArrowChaosGame.rewardedHintAmount);
    expect(game.hud.value.hintsRemaining, 2);
    expect(game.hud.value.rewardedHintUsed, isTrue);

    game.showHint();
    game.showHint();
    game.grantBonusHints(ArrowChaosGame.rewardedHintAmount);
    expect(game.hud.value.hintsRemaining, 0);
  });

  test('restarting starts a new hint allowance', () async {
    final game = ArrowChaosGame(hapticsEnabled: () => false);
    game.onGameResize(Vector2(400, 800));
    await game.onLoad();
    game.showHint();
    game.showHint();

    game.restartLevel();

    expect(game.hud.value.hintsRemaining, 2);
    expect(game.hud.value.rewardedHintUsed, isFalse);
  });
}
