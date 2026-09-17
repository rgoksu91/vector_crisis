import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../game/arrow_chaos_game.dart';
import '../game/models/game_hud_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/ads_service.dart';
import 'design/app_theme.dart';

class GamePage extends StatefulWidget {
  final AppController controller;
  final AdsService ads;
  final int initialLevel;

  const GamePage({
    super.key,
    required this.controller,
    required this.ads,
    required this.initialLevel,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final ArrowChaosGame game;
  bool _rewardInProgress = false;

  @override
  void initState() {
    super.initState();
    game = ArrowChaosGame(
      initialLevelIndex: widget.initialLevel - 1,
      hapticsEnabled: () => widget.controller.hapticsEnabled,
      onLevelCompleted: (level, moves) {
        widget.controller.completeLevel(level: level, moves: moves);
      },
    );
  }

  Future<void> _nextLevel(GameHudState state) async {
    if (state.phase == GamePhase.allLevelsCompleted) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (state.level >= 12 && state.level % 4 == 0) {
      await widget.ads.showInterstitial();
    }
    await widget.controller.selectLevel(state.level + 1);
    game.nextLevel();
  }

  Future<void> _rewardedContinue() async {
    if (_rewardInProgress) return;
    setState(() => _rewardInProgress = true);
    final earned = await widget.ads.showRewarded();
    if (!mounted) return;
    setState(() => _rewardInProgress = false);
    if (earned) {
      game.grantBonusMoves(3);
    } else {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.rewardUnavailable)));
    }
  }

  Future<void> _showPause() async {
    final l10n = AppLocalizations.of(context);
    game.pauseEngine();
    final action = await showDialog<_PauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.gamePaused),
        content: Text(l10n.gamePausedBody),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, _PauseAction.resume),
            child: Text(l10n.resume),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _PauseAction.restart),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.restartLevel),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _PauseAction.home),
            icon: const Icon(Icons.home_rounded),
            label: Text(l10n.mainMenu),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _PauseAction.restart:
        game.resumeEngine();
        game.restartLevel();
      case _PauseAction.home:
        Navigator.pop(context);
      default:
        game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          ValueListenableBuilder<GameHudState>(
            valueListenable: game.hud,
            builder: (context, state, _) => _Hud(
              game: game,
              state: state,
              rewardInProgress: _rewardInProgress,
              onPause: _showPause,
              onHome: () => Navigator.pop(context),
              onNext: () => _nextLevel(state),
              onRewardedContinue: _rewardedContinue,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PauseAction { resume, restart, home }

class _Hud extends StatelessWidget {
  final ArrowChaosGame game;
  final GameHudState state;
  final bool rewardInProgress;
  final VoidCallback onPause;
  final VoidCallback onHome;
  final VoidCallback onNext;
  final VoidCallback onRewardedContinue;

  const _Hud({
    required this.game,
    required this.state,
    required this.rewardInProgress,
    required this.onPause,
    required this.onHome,
    required this.onNext,
    required this.onRewardedContinue,
  });

  int get _earnedStars {
    final limit = state.moveLimit;
    if (limit == null) return 3;
    final optimum = limit - 2;
    if (state.moves <= optimum) return 3;
    if (state.moves == optimum + 1) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.home_rounded,
                  tooltip: l10n.homeTooltip,
                  onTap: onHome,
                ),
                const SizedBox(width: 9),
                _CircleButton(
                  icon: Icons.refresh_rounded,
                  tooltip: l10n.restartTooltip,
                  onTap: game.restartLevel,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.levelNumber(state.level),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.moveLimit == null
                            ? l10n.arrowsRemaining(state.remaining)
                            : l10n.arrowsAndMoves(
                                state.remaining,
                                state.moves,
                                state.moveLimit!,
                              ),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.58),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CircleButton(
                  icon: Icons.lightbulb_rounded,
                  tooltip: l10n.hintTooltip,
                  onTap: state.phase == GamePhase.playing
                      ? game.showHint
                      : null,
                ),
                const SizedBox(width: 9),
                _CircleButton(
                  icon: Icons.pause_rounded,
                  tooltip: l10n.pauseTooltip,
                  onTap: onPause,
                ),
              ],
            ),
          ),
          if (state.combo >= 2 && state.phase == GamePhase.playing)
            Positioned(
              top: 78,
              left: 0,
              right: 0,
              child: Center(
                child: _Pill(
                  text: 'COMBO x${state.combo}',
                  color: AppColors.primary,
                ),
              ),
            ),
          if (state.message != GameHudMessage.none &&
              state.phase == GamePhase.playing)
            Positioned(
              bottom: 28,
              left: 20,
              right: 20,
              child: Center(
                child: _Pill(
                  text: _localizedGameMessage(l10n, state),
                  color: AppColors.surfaceLight,
                ),
              ),
            ),
          if (state.phase != GamePhase.playing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.68),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.82, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: _ResultCard(
                      state: state,
                      stars: _earnedStars,
                      rewardInProgress: rewardInProgress,
                      onNext: onNext,
                      onRestart: game.restartLevel,
                      onHome: onHome,
                      onRewardedContinue: onRewardedContinue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GameHudState state;
  final int stars;
  final bool rewardInProgress;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onRewardedContinue;

  const _ResultCard({
    required this.state,
    required this.stars,
    required this.rewardInProgress,
    required this.onNext,
    required this.onRestart,
    required this.onHome,
    required this.onRewardedContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failed = state.phase == GamePhase.failed;
    final jammed = failed && state.message == GameHudMessage.boardJammed;
    final allDone = state.phase == GamePhase.allLevelsCompleted;
    return Container(
      width: 320,
      margin: const EdgeInsets.all(22),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (failed ? AppColors.danger : AppColors.primary).withValues(
            alpha: 0.38,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            failed ? Icons.replay_rounded : Icons.auto_awesome_rounded,
            size: 46,
            color: failed ? AppColors.danger : AppColors.gold,
          ),
          const SizedBox(height: 12),
          Text(
            jammed
                ? l10n.boardJammedTitle
                : failed
                ? l10n.movesEnded
                : allDone
                ? l10n.allLevelsCompleted
                : l10n.boardClear,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (!failed)
            Text(
              List.generate(3, (index) => index < stars ? '★' : '☆').join(' '),
              style: const TextStyle(
                fontSize: 29,
                color: AppColors.gold,
                letterSpacing: 2,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            jammed
                ? l10n.boardJammedDescription
                : failed
                ? l10n.failedDescription
                : allDone
                ? l10n.allDoneDescription
                : l10n.completedInMoves(state.moves),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          if (failed) ...[
            // Extra moves cannot open a jammed board, so only restart is offered.
            if (!jammed) ...[
              FilledButton.icon(
                onPressed: rewardInProgress ? null : onRewardedContinue,
                icon: rewardInProgress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ondemand_video_rounded),
                label: Text(l10n.watchAdBonus),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: onRestart,
              child: Text(l10n.restart),
            ),
          ] else
            FilledButton(
              onPressed: onNext,
              child: Text(allDone ? l10n.returnToMainMenu : l10n.nextLevel),
            ),
          const SizedBox(height: 6),
          TextButton(onPressed: onHome, child: Text(l10n.mainMenu)),
        ],
      ),
    );
  }
}

String _localizedGameMessage(AppLocalizations l10n, GameHudState state) =>
    switch (state.message) {
      GameHudMessage.none => '',
      GameHudMessage.frozenArrowBlocked => l10n.frozenArrowBlocked,
      GameHudMessage.rotatorTurned => l10n.rotatorTurned,
      GameHudMessage.pathBlocked => l10n.pathBlocked,
      GameHudMessage.combo => 'COMBO x${state.messageValue}',
      GameHudMessage.noAvailableMove => l10n.noAvailableMove,
      GameHudMessage.hintRotate => l10n.hintRotate,
      GameHudMessage.hintMarked => l10n.hintMarked,
      GameHudMessage.bonusMoves => l10n.bonusMovesGranted(state.messageValue),
      GameHudMessage.bomb =>
        state.messageValue == 0 ? 'BOOM!' : l10n.bombResult(state.messageValue),
      GameHudMessage.campaignCompleted => l10n.campaignCompletedMessage,
      GameHudMessage.boardClear => l10n.boardClearMessage,
      GameHudMessage.moveLimitReached => l10n.moveLimitReached,
      GameHudMessage.boardJammed => l10n.boardJammed,
      GameHudMessage.introTapArrow => l10n.introTapArrow,
      GameHudMessage.introRotator => l10n.introRotator,
      GameHudMessage.introFrozen => l10n.introFrozen,
      GameHudMessage.introBomb => l10n.introBomb,
      GameHudMessage.introRotatorClockwise => l10n.introRotatorClockwise,
      GameHudMessage.introStone => l10n.introStone,
    };

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
    ),
  );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 43,
          height: 43,
          child: Icon(
            icon,
            size: 21,
            color: onTap == null ? Colors.white24 : Colors.white,
          ),
        ),
      ),
    ),
  );
}
