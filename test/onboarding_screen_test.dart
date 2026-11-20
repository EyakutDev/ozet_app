import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/screens/onboarding_screen.dart';
import 'package:ozet_app/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('onboarding presents news, partner, then daily score', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Gündem, uzatmadan.'), findsOneWidget);
    expect(find.text('bbc rss'), findsNWidgets(3));
    expect(find.textContaining('Şanghay İşbirliği Örgütü'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Birlikte, ama sakin.'), findsOneWidget);
    expect(find.text('Hızlı durum'), findsOneWidget);
    expect(find.text('Mini not'), findsOneWidget);
    expect(find.text('Çizim'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Günün sende kalsın.'), findsOneWidget);
    expect(find.text('Gün kartın'), findsOneWidget);
    expect(find.text('Takvim'), findsOneWidget);
    expect(find.text('Haftalık analiz'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
  });

  testWidgets('onboarding fits a compact phone in dark mode', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const OnboardingScreen()),
    );
    expect(tester.takeException(), isNull);

    for (var page = 1; page < 3; page++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('partner scene responds only after the user taps it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Paylaşıldı'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('onboarding-partner-action')));
    await tester.pumpAndSettle();

    expect(find.text('Paylaşıldı'), findsOneWidget);
  });

  testWidgets('daily score scene lets the user adjust the score', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    for (var page = 0; page < 2; page++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
    }

    final sliderFinder = find.byKey(const ValueKey('onboarding-score-slider'));
    final initialSlider = tester.widget<Semantics>(sliderFinder);
    expect(initialSlider.properties.value, '7 / 10');

    final sliderBounds = tester.getRect(sliderFinder);
    await tester.tapAt(Offset(sliderBounds.right - 20, sliderBounds.center.dy));
    await tester.pumpAndSettle();

    final updatedSlider = tester.widget<Semantics>(sliderFinder);
    expect(updatedSlider.properties.value, isNot('7 / 10'));
  });
  testWidgets('preview mode closes without completing onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(previewMode: true),
                ),
              ),
              child: const Text('Önizlemeyi aç'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Önizlemeyi aç'));
    await tester.pumpAndSettle();
    expect(find.text('Kapat'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Önizlemeyi aç'), findsOneWidget);
    expect(await OnboardingService().hasCompleted(), isFalse);
  });
}
