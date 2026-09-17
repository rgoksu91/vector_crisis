typedef AdClock = DateTime Function();

/// Keeps full-screen ads at natural breaks and prevents back-to-back ads.
///
/// The first interstitial cannot appear during the tutorial. Afterwards the
/// player must both clear enough levels and spend enough time in the game.
class AdPacingPolicy {
  static const firstInterstitialLevel = 8;
  static const levelsBetweenInterstitials = 3;
  static const firstInterstitialDelay = Duration(minutes: 2);
  static const fullScreenCooldown = Duration(minutes: 3);

  final AdClock _now;
  late final DateTime _sessionStartedAt;
  DateTime? _lastFullScreenAt;
  int _completionsSinceInterstitial = 0;

  AdPacingPolicy({AdClock? now}) : _now = now ?? DateTime.now {
    _sessionStartedAt = _now();
  }

  void recordLevelCompleted() {
    _completionsSinceInterstitial++;
  }

  bool canShowInterstitialAfter(int completedLevel) {
    if (completedLevel < firstInterstitialLevel ||
        _completionsSinceInterstitial < levelsBetweenInterstitials) {
      return false;
    }

    final now = _now();
    final lastFullScreenAt = _lastFullScreenAt;
    if (lastFullScreenAt != null) {
      return now.difference(lastFullScreenAt) >= fullScreenCooldown;
    }
    return now.difference(_sessionStartedAt) >= firstInterstitialDelay;
  }

  void recordInterstitialShown() {
    _lastFullScreenAt = _now();
    _completionsSinceInterstitial = 0;
  }

  void recordRewardedShown() {
    _lastFullScreenAt = _now();
  }
}
