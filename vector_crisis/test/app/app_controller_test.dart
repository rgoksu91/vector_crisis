import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_crisis/app/app_controller.dart';

void main() {
  test('progress, stars, selection and settings persist', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();

    expect(controller.unlockedLevel, 1);
    expect(controller.hasProgress, isFalse);

    await controller.completeLevel(level: 1, moves: 1);
    await controller.selectLevel(2);
    await controller.setHapticsEnabled(false);
    await controller.setLocaleCode('tr');

    expect(controller.unlockedLevel, 2);
    expect(controller.lastLevel, 2);
    expect(controller.completedLevels, 1);
    expect(controller.starsFor(1), 3);

    final restored = AppController();
    await restored.initialize();
    expect(restored.unlockedLevel, 2);
    expect(restored.lastLevel, 2);
    expect(restored.bestMovesFor(1), 1);
    expect(restored.hapticsEnabled, isFalse);
    expect(restored.localeCode, 'tr');

    await restored.setLocaleCode(null);
    expect(restored.localeCode, isNull);

    await restored.resetProgress();
    expect(restored.unlockedLevel, 1);
    expect(restored.completedLevels, 0);

    controller.dispose();
    restored.dispose();
  });
}
