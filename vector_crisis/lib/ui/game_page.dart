import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/arrow_chaos_game.dart';
import '../game/models/game_hud_state.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final ArrowChaosGame game;

  @override
  void initState() {
    super.initState();
    game = ArrowChaosGame();
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
            builder: (context, state, _) {
              return _Hud(game: game, state: state);
            },
          ),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  final ArrowChaosGame game;
  final GameHudState state;

  const _Hud({required this.game, required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Restart',
                    onTap: game.restartLevel,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'LEVEL ${state.level}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          state.moveLimit == null
                              ? '${state.remaining} arrow left'
                              : '${state.remaining} arrow  •  '
                                    '${state.moves}/${state.moveLimit} moves',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CircleButton(
                    icon: Icons.lightbulb_rounded,
                    tooltip: 'Hint',
                    onTap: state.phase == GamePhase.playing
                        ? game.showHint
                        : null,
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C8CFF).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFF9AA5FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      child: Text(
                        'COMBO x${state.combo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE2E5FF),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (state.message.isNotEmpty && state.phase == GamePhase.playing)
              Positioned(
                bottom: 32,
                left: 20,
                right: 20,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xCC171B31),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            if (state.phase != GamePhase.playing)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181D34),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFF7C8CFF)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.phase == GamePhase.failed ? '↻' : '✨',
                            style: const TextStyle(fontSize: 42),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            switch (state.phase) {
                              GamePhase.failed => 'OUT OF MOVES',
                              GamePhase.allLevelsCompleted =>
                                '${state.totalLevels} LEVELS CLEARED',
                              _ => 'BOARD CLEAR',
                            },
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            switch (state.phase) {
                              GamePhase.failed =>
                                'Daha verimli bir sıra bul ve tekrar dene.',
                              GamePhase.allLevelsCompleted =>
                                'Tüm level’lar tamamlandı.',
                              _ => 'Level ${state.level} tamamlandı.',
                            },
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: state.phase == GamePhase.failed
                                  ? game.restartLevel
                                  : game.nextLevel,
                              child: Text(switch (state.phase) {
                                GamePhase.failed => 'TEKRAR DENE',
                                GamePhase.allLevelsCompleted => 'BAŞTAN OYNA',
                                _ => 'NEXT LEVEL',
                              }),
                            ),
                          ),
                          if (state.phase != GamePhase.failed) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: game.restartLevel,
                              child: const Text('Tekrar oyna'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFF181D34),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: onTap == null ? Colors.white30 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
