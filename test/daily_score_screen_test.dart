import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/screens/daily_score_screen.dart';

void main() {
  testWidgets('starts at five and aligns the thumb with the five label', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DailyScoreScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    final thumb = find.byKey(const ValueKey('daily-score-thumb'));
    final fiveLabel = find.byKey(const ValueKey('daily-score-scale-5'));

    expect(thumb, findsOneWidget);
    expect(fiveLabel, findsOneWidget);
    expect(
      (tester.getCenter(thumb).dx - tester.getCenter(fiveLabel).dx).abs(),
      lessThan(0.5),
    );

    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('daily-score-thumb')), findsOneWidget);
  });
}
