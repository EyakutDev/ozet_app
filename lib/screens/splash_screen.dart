import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- YENİ EKLEDİK
import 'package:ozet_app/screens/auth_screen.dart'; // Giriş ekranı
import 'package:ozet_app/screens/home_screen.dart'; // Ana sayfa <-- YENİ EKLEDİK

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
  void _checkCurrentUserAndNavigate() {
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return; // Ekran kapandıysa işlem yapma (güvenlik için)

      // === İŞTE "BENİ HATIRLA" KONTROLÜ BURADA ===
      // Firebase'den mevcut kullanıcıyı kontrol et
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // KULLANICI GİRİŞ YAPMIŞ: "Beni Hatırla" çalıştı
        // Direkt Ana Sayfa'ya (HomeScreen) yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // KULLANICI GİRİŞ YAPMAMIŞ: Oturum kapalı
        // Giriş/Kayıt Ekranı'na (AuthScreen) yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
      // === KONTROL BİTTİ ===
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tasarımın (build metodu) aynı kalıyor, ona dokunmuyoruz.
    // Tasarımına uygun renkler
    final Color beyaz = Colors.white;
    // Siyah renk %61 opaklıkta
    final Color altYaziRengi = const Color(0xFF000000).withOpacity(0.61);

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
