import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- YENİ
import 'package:ozet_app/screens/splash_screen.dart';
import 'package:ozet_app/theme/app_theme_palette.dart';
import 'package:ozet_app/services/notification_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Glow efektini kaldıran yapı
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

// Global Tema Kontrolcüsü
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// Arka planda bildirim gelirse çalışacak fonksiyon
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 40 * 1024 * 1024,
  );

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Arka plan bildirim handler'i runApp oncesinde kaydedilmelidir.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Kayıtlı temayı yükle
  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool('isDarkTheme') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());

  // Ağ veya Google servisleri yavaş olsa bile ilk ekranın açılmasını engelleme.
  unawaited(_configureMessaging());
}

Future<void> _configureMessaging() async {
  try {
    await FirebaseMessaging.instance.requestPermission().timeout(
      const Duration(seconds: 8),
    );
    await FirebaseMessaging.instance
        .subscribeToTopic('all')
        .timeout(const Duration(seconds: 8));
    await NotificationPreferencesService().sync().timeout(
      const Duration(seconds: 12),
    );
  } catch (_) {
    // Bildirim kurulumu daha sonra tekrar denenebilir; uygulama açılışı sürer.
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Özet App',
          debugShowCheckedModeBanner: false,

          // Tema Ayarları
          themeMode: currentMode,
          scrollBehavior: NoGlowScrollBehavior(),

          // AÇIK TEMA
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

          // KOYU TEMA
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

          home: const SplashScreen(),
        );
      },
    );
  }
}
