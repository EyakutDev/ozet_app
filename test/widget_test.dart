import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/widgets/app_feedback.dart';

void main() {
  testWidgets('AppFeedback mesajı tema uyumlu snackbar olarak gösterilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppFeedback.show(
                context,
                'İşlem tamamlandı.',
                type: AppFeedbackType.success,
              ),
              child: const Text('Mesajı göster'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mesajı göster'));
    await tester.pump();

    expect(find.text('İşlem tamamlandı.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
