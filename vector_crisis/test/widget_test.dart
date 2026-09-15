import 'package:flutter_test/flutter_test.dart';
import 'package:vector_crisis/main.dart';

void main() {
  testWidgets('game shell loads the first level', (tester) async {
    await tester.pumpWidget(const ArrowChaosApp());
    await tester.pump();

    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('1 arrow left'), findsOneWidget);
  });
}
