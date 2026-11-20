import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/core/errors/app_failure.dart';
import 'package:ozet_app/widgets/app_feedback.dart';

void main() {
  testWidgets('runs the retry action from an error message', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppFeedback.show(
                context,
                'İşlem tamamlanamadı.',
                type: AppFeedbackType.error,
                actionLabel: 'Tekrar dene',
                onAction: () => retryCount += 1,
              ),
              child: const Text('Hata göster'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Hata göster'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Tekrar dene'));
    await tester.pump();

    expect(retryCount, 1);
  });
  testWidgets('only offers retry when the failure policy allows it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppFeedback.showFailure(
                context,
                const AppFailure(
                  kind: AppFailureKind.invalidInput,
                  code: 'invalid-input',
                  userMessage: 'Girilen bilgileri kontrol edin.',
                  recoveryAction: AppRecoveryAction.none,
                  reportable: false,
                ),
                onRetry: () {},
              ),
              child: const Text('Hata göster'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Hata göster'));
    await tester.pump();

    expect(find.text('Girilen bilgileri kontrol edin.'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsNothing);
  });
}
