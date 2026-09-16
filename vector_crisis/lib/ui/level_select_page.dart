import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../game/data/levels.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/ads_service.dart';
import 'design/animated_background.dart';
import 'design/app_theme.dart';
import 'design/navigation.dart';
import 'game_page.dart';

class LevelSelectPage extends StatelessWidget {
  final AppController controller;
  final AdsService ads;

  const LevelSelectPage({
    super.key,
    required this.controller,
    required this.ads,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.selectLevel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${controller.totalStars} ★',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final unlocked = level <= controller.unlockedLevel;
                      final stars = controller.starsFor(level);
                      return _LevelTile(
                        level: level,
                        unlocked: unlocked,
                        stars: stars,
                        current: level == controller.lastLevel,
                        onTap: !unlocked
                            ? null
                            : () async {
                                await controller.selectLevel(level);
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  appRoute(
                                    GamePage(
                                      controller: controller,
                                      ads: ads,
                                      initialLevel: level,
                                    ),
                                  ),
                                );
                              },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int level;
  final bool unlocked;
  final int stars;
  final bool current;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: current
          ? AppColors.primary.withValues(alpha: 0.24)
          : AppColors.surface.withValues(alpha: unlocked ? 0.9 : 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: current
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!unlocked)
                const Icon(Icons.lock_rounded, size: 20, color: Colors.white24)
              else
                Text(
                  '$level',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 7),
              Text(
                stars == 0
                    ? '•••'
                    : List.generate(3, (i) => i < stars ? '★' : '·').join(),
                style: TextStyle(
                  color: stars == 0 ? Colors.white24 : AppColors.gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
