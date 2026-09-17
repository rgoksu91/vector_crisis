import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/services/ad_pacing_policy.dart';

void main() {
  late DateTime now;
  late AdPacingPolicy policy;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    policy = AdPacingPolicy(now: () => now);
  });

  test('does not interrupt the tutorial or a short first session', () {
    for (var level = 1; level <= 7; level++) {
      policy.recordLevelCompleted();
      now = now.add(const Duration(minutes: 1));
      expect(policy.canShowInterstitialAfter(level), isFalse);
    }

    final freshPolicy = AdPacingPolicy(now: () => now);
    for (var level = 1; level <= 8; level++) {
      freshPolicy.recordLevelCompleted();
    }
    expect(freshPolicy.canShowInterstitialAfter(8), isFalse);
  });

  test('shows only after enough time and completed levels', () {
    for (var level = 1; level <= 8; level++) {
      policy.recordLevelCompleted();
    }
    now = now.add(AdPacingPolicy.firstInterstitialDelay);

    expect(policy.canShowInterstitialAfter(8), isTrue);
    policy.recordInterstitialShown();

    now = now.add(AdPacingPolicy.fullScreenCooldown);
    policy.recordLevelCompleted();
    policy.recordLevelCompleted();
    expect(policy.canShowInterstitialAfter(10), isFalse);

    policy.recordLevelCompleted();
    expect(policy.canShowInterstitialAfter(11), isTrue);
  });

  test('rewarded ad starts a full-screen cooldown', () {
    for (var level = 1; level <= 10; level++) {
      policy.recordLevelCompleted();
    }
    now = now.add(const Duration(minutes: 5));
    policy.recordRewardedShown();

    expect(policy.canShowInterstitialAfter(10), isFalse);
    now = now.add(AdPacingPolicy.fullScreenCooldown);
    expect(policy.canShowInterstitialAfter(10), isTrue);
  });
}
