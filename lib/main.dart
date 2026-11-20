import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/core/diagnostics/app_logger.dart';
import 'package:ozet_app/core/errors/app_error_handler.dart';
import 'package:ozet_app/screens/splash_screen.dart';
import 'package:ozet_app/services/notification_preferences_service.dart';
import 'package:ozet_app/theme/app_theme_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  final startupStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(MyApp(initializer: _initializeApplication));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    startupStopwatch.stop();
    AppLogger.event(
      'startup_first_frame',
      context: {'durationMs': startupStopwatch.elapsedMilliseconds},
    );
  });
}

bool _runtimeConfigured = false;

Future<void> _initializeApplication() async {
  final firebaseStopwatch = Stopwatch()..start();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp().timeout(const Duration(seconds: 12));
    }
    firebaseStopwatch.stop();

    if (!_runtimeConfigured) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 40 * 1024 * 1024,
      );
      await AppLogger.initialize().timeout(const Duration(seconds: 5));
      _installErrorHandlers();
      FirebaseAuth.instance.authStateChanges().listen(
        (user) => unawaited(AppLogger.setUser(user?.uid)),
        onError: (Object error, StackTrace stackTrace) => unawaited(
          AppLogger.recordError(
            error,
            stackTrace,
            operation: 'auth.state_changes',
            code: 'auth-state-stream',
          ),
        ),
      );
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      _runtimeConfigured = true;
    }

    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
    );
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    AppLogger.event(
      'startup_firebase_ready',
      context: {'durationMs': firebaseStopwatch.elapsedMilliseconds},
    );
    if (const bool.fromEnvironment('CRASHLYTICS_SMOKE_TEST')) {
      unawaited(
        AppLogger.recordError(
          StateError('Crashlytics smoke test'),
          StackTrace.current,
          operation: 'diagnostics.crashlytics_smoke_test',
          code: 'smoke-test',
        ),
      );
    }

    unawaited(_configureMessaging());
  } catch (error, stackTrace) {
    AppLogger.event(
      'startup_failed',
      level: AppLogLevel.error,
      context: {'errorType': error.runtimeType.toString()},
    );
    unawaited(
      AppLogger.recordError(
        error,
        stackTrace,
        operation: 'startup.initialize',
        code: 'startup-failed',
      ),
    );
    rethrow;
  }
}

void _installErrorHandlers() {
  final bindingType = WidgetsBinding.instance.runtimeType.toString();
  if (bindingType.contains('TestWidgetsFlutterBinding')) return;

  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    unawaited(AppLogger.recordFlutterError(details));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      AppLogger.recordError(
        error,
        stack,
        operation: 'platform.unhandled',
        code: 'unhandled-platform-error',
        fatal: true,
      ),
    );
    return true;
  };
}

Future<void> _configureMessaging() async {
  try {
    await NotificationPreferencesService().configureIfAuthorized().timeout(
      const Duration(seconds: 12),
    );
  } catch (error, stackTrace) {
    await AppErrorHandler.capture(
      error,
      stackTrace,
      operation: 'notifications.configure',
      fallbackMessage: 'Bildirim ayarları şu anda güncellenemedi.',
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initializer});

  final Future<void> Function() initializer;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Özet App',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          scrollBehavior: NoGlowScrollBehavior(),
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFF0A2342),
            fontFamily: GoogleFonts.kadwa().fontFamily,
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              elevation: 0,
              backgroundColor: const Color(0xFF0A2342),
              contentTextStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppThemePalette.darkScaffold,
            primaryColor: AppThemePalette.darkText,
            fontFamily: GoogleFonts.kadwa().fontFamily,
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              elevation: 0,
              backgroundColor: AppThemePalette.darkSurface,
              contentTextStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppThemePalette.darkScaffold,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: _BootstrapGate(initializer: initializer),
        );
      },
    );
  }
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate({required this.initializer});

  final Future<void> Function() initializer;

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  void _startInitialization() {
    final completer = Completer<void>();
    _initialization = completer.future;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.initializer();
        if (!completer.isCompleted) completer.complete();
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });
  }

  void _retry() {
    setState(_startInitialization);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return _StartupFailureScreen(onRetry: _retry);
        }
        return const _StartupLoadingScreen();
      },
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox.square(
          key: const ValueKey('startup-loading'),
          dimension: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _StartupFailureScreen extends StatelessWidget {
  const _StartupFailureScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 32,
                  color: colors.onSurface,
                ),
                const SizedBox(height: 16),
                Text(
                  'Uygulama başlatılamadı',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bağlantını kontrol edip yeniden dene.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('startup-retry'),
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.onSurface,
                    foregroundColor: colors.surface,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Yeniden dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
