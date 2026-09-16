import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../services/ads_service.dart';
import 'design/animated_background.dart';
import 'design/app_theme.dart';
import 'design/navigation.dart';
import 'game_page.dart';
import 'level_select_page.dart';
import 'settings_sheet.dart';

class HomePage extends StatefulWidget {
  final AppController controller;
  final AdsService ads;

  const HomePage({super.key, required this.controller, required this.ads});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _openGame(int level) async {
    await widget.controller.selectLevel(level);
    if (!mounted) return;
    await Navigator.of(context).push(
      appRoute(
        GamePage(
          controller: widget.controller,
          ads: widget.ads,
          initialLevel: level,
        ),
      ),
    );
  }

  Future<void> _newGame() async {
    if (widget.controller.hasProgress) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Yeni oyun başlat?'),
          content: const Text('Mevcut ilerleme ve tüm yıldızlar silinecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('VAZGEÇ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('YENİ OYUN'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await widget.controller.resetProgress();
    await _openGame(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.controller, _pulse]),
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Ayarlar',
                        onPressed: () => showSettingsSheet(
                          context,
                          controller: widget.controller,
                          ads: widget.ads,
                        ),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Transform.scale(
                    scale: 1 + _pulse.value * 0.035,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/branding/app_icon_concept_v1.png',
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'VECTOR CRISIS',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'ARROW PUZZLE',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Her oku oku. Sırayı çöz. Kaosu temizle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                  ),
                  const SizedBox(height: 34),
                  if (widget.controller.hasProgress) ...[
                    FilledButton.icon(
                      onPressed: () => _openGame(widget.controller.lastLevel),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        'DEVAM ET  •  LEVEL ${widget.controller.lastLevel}',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _newGame,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('YENİ OYUN'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      appRoute(
                        LevelSelectPage(
                          controller: widget.controller,
                          ads: widget.ads,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('LEVEL SEÇ'),
                  ),
                  const SizedBox(height: 30),
                  _ProgressCard(controller: widget.controller),
                  const SizedBox(height: 18),
                  Text(
                    '100 HANDCRAFTED PUZZLES',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.32),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final AppController controller;

  const _ProgressCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              value: '${controller.completedLevels}',
              label: 'TAMAMLANDI',
            ),
          ),
          Container(width: 1, height: 38, color: Colors.white12),
          Expanded(
            child: _Stat(
              value: '${controller.totalStars}/300',
              label: 'YILDIZ',
            ),
          ),
          Container(width: 1, height: 38, color: Colors.white12),
          Expanded(
            child: _Stat(
              value: '${controller.unlockedLevel}',
              label: 'AÇIK LEVEL',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.42),
        ),
      ),
    ],
  );
}
