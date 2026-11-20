import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

enum AppLogLevel { info, warning, error }

class AppLogger {
  AppLogger._();

  static FirebaseCrashlytics? _crashlytics;

  static Future<void> initialize() async {
    if (kIsWeb || Firebase.apps.isEmpty) return;

    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    _crashlytics = crashlytics;
    event('diagnostics_ready', context: {'remoteEnabled': !kDebugMode});
  }

  static Future<void> setUser(String? userId) async {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    await crashlytics.setUserIdentifier(userId ?? 'signed_out');
  }

  static void event(
    String name, {
    AppLogLevel level = AppLogLevel.info,
    Map<String, Object?> context = const {},
  }) {
    final payload = <String, Object?>{
      'event': _safeText(name, 80),
      'level': level.name,
      ..._sanitizeContext(context),
    };
    final encoded = jsonEncode(payload);
    if (kDebugMode) debugPrint('[OZET] $encoded');
    _crashlytics?.log(encoded);
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String operation,
    String? code,
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {
    final safeContext = _sanitizeContext({
      'operation': operation,
      if (code != null) 'code': code,
      ...context,
    });

    event(
      fatal ? 'fatal_error' : 'operation_failed',
      level: AppLogLevel.error,
      context: safeContext,
    );

    final crashlytics = _crashlytics;
    if (crashlytics == null) return;

    await crashlytics.setCustomKey('last_operation', _safeText(operation, 80));
    if (code != null) {
      await crashlytics.setCustomKey('last_error_code', _safeText(code, 80));
    }
    await crashlytics.recordError(
      error,
      stackTrace,
      reason: operation,
      information: safeContext.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .toList(growable: false),
      fatal: fatal,
    );
  }

  static Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = true,
  }) async {
    event(
      fatal ? 'flutter_fatal_error' : 'flutter_error',
      level: AppLogLevel.error,
      context: {'library': details.library ?? 'unknown'},
    );

    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    if (fatal) {
      await crashlytics.recordFlutterFatalError(details);
    } else {
      await crashlytics.recordFlutterError(details);
    }
  }

  static Map<String, Object> _sanitizeContext(Map<String, Object?> context) {
    final sanitized = <String, Object>{};
    for (final entry in context.entries.take(16)) {
      final key = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
      final value = entry.value;
      if (value == null) continue;
      sanitized[_safeText(key, 48)] = switch (value) {
        bool() || int() || double() => value,
        _ => _safeText(value.toString(), 120),
      };
    }
    return sanitized;
  }

  static String _safeText(String value, int maxLength) {
    final normalized = value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    if (normalized.length <= maxLength) return normalized;
    return normalized.substring(0, maxLength);
  }
}
