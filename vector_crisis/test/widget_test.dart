import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_crisis/app/app_controller.dart';
import 'package:vector_crisis/main.dart';
import 'package:vector_crisis/services/ads_service.dart';

void main() {
  testWidgets('home starts a new game at level one', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();
    await controller.setLocaleCode('en');

    await tester.pumpWidget(
      VectorCrisisApp(
        controller: controller,
        ads: AdsService(),
        showSplash: false,
        initializeAds: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('VECTOR CRISIS'), findsOneWidget);
    expect(find.text('ARROW PUZZLE'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);

    await tester.tap(find.text('NEW GAME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('1 ARROW LEFT'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('Turkish can be selected independently of the device locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'settings.locale': 'tr'});
    final controller = AppController();
    await controller.initialize();

    await tester.pumpWidget(
      VectorCrisisApp(
        controller: controller,
        ads: AdsService(),
        showSplash: false,
        initializeAds: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('YENİ OYUN'), findsOneWidget);
    expect(find.text('BÖLÜM SEÇ'), findsOneWidget);

    controller.dispose();
  });
}
