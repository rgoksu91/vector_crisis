import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../game/arrow_chaos_game.dart';
import '../game/models/game_hud_state.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ödüllü reklam henüz hazır değil. Tekrar deneyebilirsin.',
          ),
        ),
      );
    }
  }

  Future<void> _showPause() async {
    game.pauseEngine();
    final action = await showDialog<_PauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('OYUN DURAKLATILDI'),
        content: const Text('Board seni bekliyor.'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, _PauseAction.resume),
            child: const Text('DEVAM ET'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _PauseAction.restart),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('LEVEL’I YENİDEN BAŞLAT'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _PauseAction.home),
            icon: const Icon(Icons.home_rounded),
            label: const Text('ANA MENÜ'),
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
                  tooltip: 'Ana menü',
                  onTap: onHome,
                ),
                const SizedBox(width: 9),
                _CircleButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Yeniden başlat',
                  onTap: game.restartLevel,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'LEVEL ${state.level}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.moveLimit == null
                            ? '${state.remaining} OK KALDI'
                            : '${state.remaining} OK  •  ${state.moves}/${state.moveLimit} HAMLE',
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
                  tooltip: 'İpucu',
                  onTap: state.phase == GamePhase.playing
                      ? game.showHint
                      : null,
                ),
                const SizedBox(width: 9),
                _CircleButton(
                  icon: Icons.pause_rounded,
                  tooltip: 'Duraklat',
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
          if (state.message.isNotEmpty && state.phase == GamePhase.playing)
            Positioned(
              bottom: 28,
              left: 20,
              right: 20,
              child: Center(
                child: _Pill(
                  text: state.message,
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
    final failed = state.phase == GamePhase.failed;
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
            failed
                ? 'HAMLE BİTTİ'
                : allDone
                ? '100 LEVEL TAMAMLANDI'
                : 'BOARD TEMİZ',
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
            failed
                ? 'Sırayı yeniden düşün veya reklam izleyerek 3 ek hamle kazan.'
                : allDone
                ? 'Kaosu tamamen kontrol altına aldın.'
                : '${state.moves} hamlede tamamlandı.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          if (failed) ...[
            FilledButton.icon(
              onPressed: rewardInProgress ? null : onRewardedContinue,
              icon: rewardInProgress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ondemand_video_rounded),
              label: const Text('REKLAM İZLE  •  +3 HAMLE'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: onRestart,
              child: const Text('YENİDEN BAŞLAT'),
            ),
          ] else
            FilledButton(
              onPressed: onNext,
              child: Text(allDone ? 'ANA MENÜYE DÖN' : 'SONRAKİ LEVEL'),
            ),
          const SizedBox(height: 6),
          TextButton(onPressed: onHome, child: const Text('ANA MENÜ')),
        ],
      ),
    );
  }
}

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
