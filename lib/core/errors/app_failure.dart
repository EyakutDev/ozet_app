import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum AppFailureKind {
  network,
  timeout,
  unauthenticated,
  permissionDenied,
  invalidInput,
  notFound,
  conflict,
  rateLimited,
  serviceUnavailable,
  localStorage,
  unknown,
}

enum AppRecoveryAction { none, retry, retryLater, signIn }

class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    required this.code,
    required this.userMessage,
    required this.recoveryAction,
    required this.reportable,
  });

  final AppFailureKind kind;
  final String code;
  final String userMessage;
  final AppRecoveryAction recoveryAction;
  final bool reportable;

  bool get canRetry => recoveryAction == AppRecoveryAction.retry;
  bool get shouldSignIn => recoveryAction == AppRecoveryAction.signIn;
  bool get isTransient => switch (kind) {
    AppFailureKind.network ||
    AppFailureKind.timeout ||
    AppFailureKind.serviceUnavailable => true,
    _ => false,
  };

  AppFailure copyWith({
    String? userMessage,
    AppRecoveryAction? recoveryAction,
  }) {
    return AppFailure(
      kind: kind,
      code: code,
      userMessage: userMessage ?? this.userMessage,
      recoveryAction: recoveryAction ?? this.recoveryAction,
      reportable: reportable,
    );
  }

  factory AppFailure.from(
    Object error, {
    String fallbackMessage = 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
  }) {
    if (error is AppFailure) return error;
    if (error is TimeoutException) return _timeout;

    if (error is FirebaseAuthException) {
      return _fromFirebaseCode(
        error.code,
        fallbackMessage: fallbackMessage,
        authError: true,
      );
    }
    if (error is FirebaseFunctionsException) {
      return _fromFirebaseCode(error.code, fallbackMessage: fallbackMessage);
    }
    if (error is FirebaseException) {
      return _fromFirebaseCode(error.code, fallbackMessage: fallbackMessage);
    }
    if (error is FormatException || error is ArgumentError) {
      return const AppFailure(
        kind: AppFailureKind.invalidInput,
        code: 'invalid-input',
        userMessage: 'Girilen bilgileri kontrol edin.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      );
    }
    if (error is StateError) {
      return AppFailure(
        kind: AppFailureKind.localStorage,
        code: 'state-error',
        userMessage: fallbackMessage,
        recoveryAction: AppRecoveryAction.retry,
        reportable: true,
      );
    }

    return AppFailure(
      kind: AppFailureKind.unknown,
      code: 'unknown',
      userMessage: fallbackMessage,
      recoveryAction: AppRecoveryAction.retry,
      reportable: true,
    );
  }

  static AppFailure _fromFirebaseCode(
    String rawCode, {
    required String fallbackMessage,
    bool authError = false,
  }) {
    final code = rawCode.toLowerCase().replaceAll('_', '-');
    return switch (code) {
      'network-request-failed' => _network,
      'deadline-exceeded' || 'timeout' => _timeout,
      'unavailable' || 'internal' => _unavailable,
      'unauthenticated' ||
      'user-token-expired' ||
      'invalid-user-token' => const AppFailure(
        kind: AppFailureKind.unauthenticated,
        code: 'unauthenticated',
        userMessage: 'Oturumunuzun süresi doldu. Yeniden giriş yapın.',
        recoveryAction: AppRecoveryAction.signIn,
        reportable: false,
      ),
      'permission-denied' => const AppFailure(
        kind: AppFailureKind.permissionDenied,
        code: 'permission-denied',
        userMessage: 'Bu işlem için yetkiniz bulunmuyor.',
        recoveryAction: AppRecoveryAction.none,
        reportable: true,
      ),
      'too-many-requests' || 'resource-exhausted' => const AppFailure(
        kind: AppFailureKind.rateLimited,
        code: 'rate-limited',
        userMessage: 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.',
        recoveryAction: AppRecoveryAction.retryLater,
        reportable: false,
      ),
      'invalid-email' => const AppFailure(
        kind: AppFailureKind.invalidInput,
        code: 'invalid-email',
        userMessage: 'Geçerli bir e-posta adresi girin.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      'weak-password' => const AppFailure(
        kind: AppFailureKind.invalidInput,
        code: 'weak-password',
        userMessage: 'Daha güçlü bir şifre belirleyin.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      'email-already-in-use' => const AppFailure(
        kind: AppFailureKind.conflict,
        code: 'email-already-in-use',
        userMessage: 'Bu e-posta adresiyle daha önce hesap oluşturulmuş.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' ||
      'invalid-login-credentials' => const AppFailure(
        kind: AppFailureKind.unauthenticated,
        code: 'invalid-credentials',
        userMessage: 'E-posta adresi veya şifre hatalı.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      'user-disabled' => const AppFailure(
        kind: AppFailureKind.permissionDenied,
        code: 'user-disabled',
        userMessage: 'Bu hesap kullanıma kapatılmış.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      'not-found' => const AppFailure(
        kind: AppFailureKind.notFound,
        code: 'not-found',
        userMessage: 'İstenen kayıt bulunamadı.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      'failed-precondition' => const AppFailure(
        kind: AppFailureKind.conflict,
        code: 'failed-precondition',
        userMessage: 'İşlemin koşulları şu anda uygun değil.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      'already-exists' || 'aborted' => const AppFailure(
        kind: AppFailureKind.conflict,
        code: 'conflict',
        userMessage: 'İşlem başka bir değişiklikle çakıştı. Tekrar deneyin.',
        recoveryAction: AppRecoveryAction.retry,
        reportable: false,
      ),
      'cancelled' => const AppFailure(
        kind: AppFailureKind.unknown,
        code: 'cancelled',
        userMessage: 'İşlem iptal edildi.',
        recoveryAction: AppRecoveryAction.none,
        reportable: false,
      ),
      _ => AppFailure(
        kind: AppFailureKind.unknown,
        code: authError ? 'auth-$code' : 'firebase-$code',
        userMessage: fallbackMessage,
        recoveryAction: AppRecoveryAction.retry,
        reportable: true,
      ),
    };
  }

  static const _network = AppFailure(
    kind: AppFailureKind.network,
    code: 'network',
    userMessage:
        'Bağlantı kurulamadı. İnternetinizi kontrol edip tekrar deneyin.',
    recoveryAction: AppRecoveryAction.retry,
    reportable: false,
  );

  static const _timeout = AppFailure(
    kind: AppFailureKind.timeout,
    code: 'timeout',
    userMessage: 'İşlem beklenenden uzun sürdü. Tekrar deneyin.',
    recoveryAction: AppRecoveryAction.retry,
    reportable: false,
  );

  static const _unavailable = AppFailure(
    kind: AppFailureKind.serviceUnavailable,
    code: 'service-unavailable',
    userMessage: 'Servise şu anda ulaşılamıyor. Biraz sonra tekrar deneyin.',
    recoveryAction: AppRecoveryAction.retry,
    reportable: true,
  );
}
