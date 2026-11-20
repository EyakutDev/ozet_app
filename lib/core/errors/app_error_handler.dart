import 'package:ozet_app/core/diagnostics/app_logger.dart';
import 'package:ozet_app/core/errors/app_failure.dart';

class AppErrorHandler {
  AppErrorHandler._();

  static Future<AppFailure> capture(
    Object error,
    StackTrace stackTrace, {
    required String operation,
    String fallbackMessage = 'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
    Map<String, Object?> context = const {},
  }) async {
    final failure = AppFailure.from(error, fallbackMessage: fallbackMessage);
    final diagnosticContext = <String, Object?>{
      'kind': failure.kind.name,
      'recovery': failure.recoveryAction.name,
      ...context,
    };

    if (failure.reportable) {
      await AppLogger.recordError(
        error,
        stackTrace,
        operation: operation,
        code: failure.code,
        context: diagnosticContext,
      );
    } else {
      AppLogger.event(
        'handled_failure',
        level: AppLogLevel.warning,
        context: {
          'operation': operation,
          'code': failure.code,
          ...diagnosticContext,
        },
      );
    }
    return failure;
  }
}
