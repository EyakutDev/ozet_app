import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ozet_app/core/errors/app_error_handler.dart';
import 'package:ozet_app/screens/auth_screen.dart';
import 'package:ozet_app/screens/home_screen.dart';
import 'package:ozet_app/screens/onboarding_screen.dart';
import 'package:ozet_app/services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkCurrentUserAndNavigate(); // Fonksiyonu akıllı hale getirdik
  }

  // Akıllı yönlendirme fonksiyonu
  Future<void> _checkCurrentUserAndNavigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return; // Ekran kapandıysa işlem yapma (güvenlik için)

    final user = FirebaseAuth.instance.currentUser;
    final onboarding = OnboardingService();

    if (user != null) {
      try {
        await onboarding.complete();
      } catch (error, stackTrace) {
        await AppErrorHandler.capture(
          error,
          stackTrace,
          operation: 'onboarding.migrate_existing_user',
          fallbackMessage: 'Başlangıç tercihi kaydedilemedi.',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      return;
    }

    try {
      final hasCompletedOnboarding = await onboarding.hasCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => hasCompletedOnboarding
              ? const AuthScreen()
              : const OnboardingScreen(),
        ),
      );
    } catch (error, stackTrace) {
      await AppErrorHandler.capture(
        error,
        stackTrace,
        operation: 'onboarding.load',
        fallbackMessage: 'Başlangıç tercihi okunamadı.',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tasarımın (build metodu) aynı kalıyor, ona dokunmuyoruz.
    // Tasarımına uygun renkler
    final Color beyaz = Colors.white;
    // Siyah renk %61 opaklıkta
    final Color altYaziRengi = const Color(0xFF000000).withValues(alpha: 0.61);

    return Scaffold(
      backgroundColor: beyaz,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ortadaki Logo
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/logo_ozet.png', // pubspec.yaml'a eklediğimiz logo
                width: 200,
              ),
            ),

            // 2. Alttaki "SOSYAL OLMAYAN MEDYA" yazısı
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Text(
                  "SOSYAL OLMAYAN MEDYA",
                  style: GoogleFonts.kadwa(
                    color: altYaziRengi, // Siyah %61 opaklık
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
