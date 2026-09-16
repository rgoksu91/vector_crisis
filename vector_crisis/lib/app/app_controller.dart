import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/data/levels.dart';

class AppController extends ChangeNotifier {
  static const _unlockedKey = 'progress.unlockedLevel';
  static const _lastLevelKey = 'progress.lastLevel';
  static const _hapticsKey = 'settings.haptics';
  static const _localeKey = 'settings.locale';
  static const _bestMovesPrefix = 'progress.bestMoves.';

  SharedPreferences? _preferences;
  final Map<int, int> _bestMoves = {};

  bool isReady = false;
  int unlockedLevel = 1;
  int lastLevel = 1;
  bool hapticsEnabled = true;
  String? localeCode;

  bool get hasProgress => completedLevels > 0 || unlockedLevel > 1;
  int get completedLevels => _bestMoves.length;
  int get totalStars =>
      _bestMoves.entries.fold(0, (sum, entry) => sum + starsFor(entry.key));

  Future<void> initialize() async {
    if (isReady) return;
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    unlockedLevel = preferences.getInt(_unlockedKey) ?? 1;
    lastLevel = preferences.getInt(_lastLevelKey) ?? 1;
    hapticsEnabled = preferences.getBool(_hapticsKey) ?? true;
    localeCode = preferences.getString(_localeKey);

    unlockedLevel = unlockedLevel.clamp(1, levels.length);
    lastLevel = lastLevel.clamp(1, unlockedLevel);
    for (final level in levels) {
      final moves = preferences.getInt('$_bestMovesPrefix${level.id}');
      if (moves != null) _bestMoves[level.id] = moves;
    }
    isReady = true;
    notifyListeners();
  }

  int? bestMovesFor(int level) => _bestMoves[level];

  int starsFor(int level) {
    final best = _bestMoves[level];
    final target = levels[level - 1].targetMoves;
    if (best == null) return 0;
    if (target == null || best <= target) return 3;
    if (best <= target + 1) return 2;
    return 1;
  }

  Future<void> selectLevel(int level) async {
    if (level < 1 || level > unlockedLevel) return;
    lastLevel = level;
    notifyListeners();
    await _preferences?.setInt(_lastLevelKey, lastLevel);
  }

  Future<void> completeLevel({required int level, required int moves}) async {
    final previous = _bestMoves[level];
    if (previous == null || moves < previous) {
      _bestMoves[level] = moves;
      await _preferences?.setInt('$_bestMovesPrefix$level', moves);
    }

    if (level < levels.length && unlockedLevel <= level) {
      unlockedLevel = level + 1;
      await _preferences?.setInt(_unlockedKey, unlockedLevel);
    }
    lastLevel = level < levels.length ? level + 1 : levels.length;
    await _preferences?.setInt(_lastLevelKey, lastLevel);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    for (final level in levels) {
      await _preferences?.remove('$_bestMovesPrefix${level.id}');
    }
    _bestMoves.clear();
    unlockedLevel = 1;
    lastLevel = 1;
    await _preferences?.setInt(_unlockedKey, 1);
    await _preferences?.setInt(_lastLevelKey, 1);
    notifyListeners();
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    notifyListeners();
    await _preferences?.setBool(_hapticsKey, value);
  }

  Future<void> setLocaleCode(String? value) async {
    if (value != null && value != 'en' && value != 'tr') return;
    localeCode = value;
    notifyListeners();
    if (value == null) {
      await _preferences?.remove(_localeKey);
    } else {
      await _preferences?.setString(_localeKey, value);
    }
  }
}
