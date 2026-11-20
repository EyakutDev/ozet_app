import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/main.dart';

void main() {
  testWidgets('startup failure offers a working retry action', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      MyApp(
        initializer: () async {
          attempts++;
          throw StateError('test startup failure');
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byKey(const ValueKey('startup-retry')), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.byKey(const ValueKey('startup-retry')));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byKey(const ValueKey('startup-retry')), findsOneWidget);
    expect(attempts, 2);
  });
}
