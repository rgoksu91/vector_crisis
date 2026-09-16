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

    await tester.pumpWidget(
      ArrowChaosApp(
        controller: controller,
        ads: AdsService(),
        showSplash: false,
        initializeAds: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('ARROW CHAOS'), findsOneWidget);
    expect(find.text('YENİ OYUN'), findsOneWidget);

    await tester.tap(find.text('YENİ OYUN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('1 OK KALDI'), findsOneWidget);

    controller.dispose();
  });
}
