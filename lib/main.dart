import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- YENİ
import 'package:ozet_app/screens/splash_screen.dart';
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

  // Bildirimleri dinlemeye başla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // === 1. HABER BİLDİRİMLERİNE ABONE OL ===
  // Admin panelinden "topics/all" kanalına gönderilen bildirimleri almak için
  await FirebaseMessaging.instance.subscribeToTopic('all');

  // İzin iste (iOS için özellikle gerekli)
  await FirebaseMessaging.instance.requestPermission();

  // Kayıtlı temayı yükle
  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool('isDarkTheme') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
              contentTextStyle: GoogleFonts.kadwa(
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
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: const Color(0xFF9EC8ED),
            fontFamily: GoogleFonts.kadwa().fontFamily,
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              elevation: 0,
              backgroundColor: const Color(0xFF1E1E1E),
              contentTextStyle: GoogleFonts.kadwa(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
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
