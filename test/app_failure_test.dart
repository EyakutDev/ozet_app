import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/core/errors/app_failure.dart';

void main() {
  group('AppFailure decision policy', () {
    test('network failures can be retried without remote error noise', () {
      final failure = AppFailure.from(
        FirebaseAuthException(code: 'network-request-failed'),
      );

      expect(failure.kind, AppFailureKind.network);
      expect(failure.recoveryAction, AppRecoveryAction.retry);
      expect(failure.reportable, isFalse);
    });

    test('expired sessions require sign in instead of retry', () {
      final failure = AppFailure.from(
        FirebaseAuthException(code: 'user-token-expired'),
      );

      expect(failure.kind, AppFailureKind.unauthenticated);
      expect(failure.shouldSignIn, isTrue);
      expect(failure.canRetry, isFalse);
    });

    test('invalid credentials show a safe message and are not reportable', () {
      final failure = AppFailure.from(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Technical provider detail',
        ),
      );

      expect(failure.code, 'invalid-credentials');
      expect(failure.userMessage, 'E-posta adresi veya şifre hatalı.');
      expect(failure.userMessage, isNot(contains('provider')));
      expect(failure.reportable, isFalse);
    });

    test('permission failures are visible to diagnostics without retry', () {
      final failure = AppFailure.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      expect(failure.kind, AppFailureKind.permissionDenied);
      expect(failure.recoveryAction, AppRecoveryAction.none);
      expect(failure.reportable, isTrue);
    });

    test(
      'failed preconditions are expected and do not pollute Crashlytics',
      () {
        final failure = AppFailure.from(
          FirebaseException(
            plugin: 'cloud_functions',
            code: 'failed-precondition',
          ),
        );

        expect(failure.code, 'failed-precondition');
        expect(failure.recoveryAction, AppRecoveryAction.none);
        expect(failure.reportable, isFalse);
      },
    );
    test('timeouts are transient and retryable', () {
      final failure = AppFailure.from(TimeoutException('slow request'));

      expect(failure.kind, AppFailureKind.timeout);
      expect(failure.isTransient, isTrue);
      expect(failure.canRetry, isTrue);
    });

    test('unexpected failures use the supplied safe fallback', () {
      final failure = AppFailure.from(
        Exception('database internals'),
        fallbackMessage: 'Kayıt şu anda tamamlanamadı.',
      );

      expect(failure.kind, AppFailureKind.unknown);
      expect(failure.userMessage, 'Kayıt şu anda tamamlanamadı.');
      expect(failure.reportable, isTrue);
    });
  });
}
