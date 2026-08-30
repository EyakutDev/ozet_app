import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/widgets/home_panel_controls.dart';

void main() {
  testWidgets('compact footer keeps its content inside the panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              child: HomePanelFooter(
                activeIndex: 0,
                foregroundColor: Colors.black,
                mutedColor: Colors.grey,
                actionLabel: 'Değerlendir',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Değerlendir'), findsOneWidget);
    expect(find.byType(HomePanelPageIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
