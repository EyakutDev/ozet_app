import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ozet_app/main.dart' as app;
import 'package:ozet_app/screens/auth_screen.dart';
import 'package:ozet_app/screens/home_screen.dart';
import 'package:ozet_app/screens/onboarding_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts and reaches its first destination', (tester) async {
    await app.main();
    await tester.pump();

    expect(find.byKey(const ValueKey('startup-loading')), findsOneWidget);

    var destinationCount = 0;
    for (var attempt = 0; attempt < 80 && destinationCount == 0; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      destinationCount =
          find.byType(AuthScreen).evaluate().length +
          find.byType(HomeScreen).evaluate().length +
          find.byType(OnboardingScreen).evaluate().length;
    }

    expect(destinationCount, 1);
  });
}
