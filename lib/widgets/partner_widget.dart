import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ozet_app/screens/settings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PartnerWidget extends StatefulWidget {
  const PartnerWidget({Key? key}) : super(key: key);

  @override
  State<PartnerWidget> createState() => _PartnerWidgetState();
}

class _PartnerWidgetState extends State<PartnerWidget> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // === TEMA RENGİ ALGILAMA ===
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Kartın Arka Plan Rengi
    Color cardBackgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // Yazı Renkleri
    Color primaryTextColor = isDark ? Colors.white : Colors.black87;
    Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.black54;

    // === RENK MANTIĞI (3. KART İÇİN GÜNCELLENDİ) ===
    // 0: Detoks (Teal), 1: Partner (Red), 2: Sen (Blue)
    Color themeColor;
    if (_currentPage == 0) {
      themeColor = Colors.teal;
    } else if (_currentPage == 1) {
      themeColor = Colors.redAccent;
    } else {
      themeColor = Colors.blueAccent; // <-- Senin kartının rengi
    }

    // Gölge rengi tema rengine göre değişir
    Color shadowColor = themeColor.withOpacity(isDark ? 0.3 : 0.5);

    if (user == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildDetoxPage(
            context,
            Colors.teal,
            primaryTextColor,
            secondaryTextColor,
            fallbackNewsCount: 5,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildLoading();

            var userData = snapshot.data!.data() as Map<String, dynamic>?;
            String? partnerId = userData?['pairedWith'];

            // === SENİN DURUM BİLGİLERİN ===
            String myIcon = userData?['statusIcon'] ?? "🤔";
            String myText = userData?['statusText'] ?? "Durum Ayarla";

            return PageView(
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // 1. KART: Detoks Sayfası
                _buildDetoxPage(
                  context,
                  Colors.teal, // Sabit renk
                  primaryTextColor,
                  secondaryTextColor,
                ),

                // 2. KART: Partner Sayfası
                partnerId == null
                    ? _buildConnectPage(
                        context,
                        primaryTextColor,
                        secondaryTextColor,
                      )
                    : _buildPartnerPage(
                        context,
                        user.uid,
                        partnerId,
                        primaryTextColor,
                        secondaryTextColor,
                      ),

                // 3. KART (YENİ): Senin Profilin/Durumun
                _buildMyStatusPage(
                  context,
                  user.uid,
                  myIcon,
                  myText,
                  primaryTextColor,
                  secondaryTextColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF9EC8ED),
        strokeWidth: 2,
      ),
    );
  }

  // --- 1. DETOKS SAYFASI ---
  Widget _buildDetoxPage(
    BuildContext context,
    Color themeColor,
    Color primaryText,
    Color secondaryText, {
    int fallbackNewsCount = 0,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        int newsCount = fallbackNewsCount;
        if (snapshot.hasData) newsCount = snapshot.data!.docs.length;
        int savedMinutes = newsCount * 4;

        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Detoks",
                    style: GoogleFonts.kadwa(
                      fontSize: 14,
                      color: secondaryText,
                    ),
                  ),
                  Icon(Icons.spa, size: 18, color: themeColor),
                ],
              ),
              Text(
                "$savedMinutes dk",
                style: GoogleFonts.kadwa(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeColor.withOpacity(0.9),
                ),
              ),
              Text(
                "kazandın",
                style: GoogleFonts.kadwa(fontSize: 12, color: secondaryText),
              ),
              const SizedBox(height: 5),
              Text(
                "$newsCount Özet",
                style: GoogleFonts.kadwa(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BAĞLANMA EKRANI ---
  Widget _buildConnectPage(
    BuildContext context,
    Color primaryText,
    Color secondaryText,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 30, color: secondaryText),
            const SizedBox(height: 8),
            Text(
              "Eşleşmek için\ntıkla",
              textAlign: TextAlign.center,
              style: GoogleFonts.kadwa(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. PARTNER SAYFASI ---
  Widget _buildPartnerPage(
    BuildContext context,
    String myUid,
    String partnerId,
    Color primaryText,
    Color secondaryText,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(partnerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        String icon = data?['statusIcon'] ?? "👋";
        String text = data?['statusText'] ?? "Müsait";

        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Partner",
                    style: GoogleFonts.kadwa(
                      fontSize: 14,
                      color: secondaryText,
                    ),
                  ),
                  const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
                ],
              ),
              Center(child: Text(icon, style: const TextStyle(fontSize: 32))),
              Center(
                child: Text(
                  text,
                  style: GoogleFonts.kadwa(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Partner sayfasında sağ ok ikonu (3. sayfaya gitmek için ipucu)
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. KART: SENİN PROFİLİN (YENİ EKLENEN KISIM) ---
  // Tasarım birebir Partner sayfasıyla aynı, sadece veriler senin.
  Widget _buildMyStatusPage(
    BuildContext context,
    String myUid,
    String myIcon,
    String myText,
    Color primaryText,
    Color secondaryText,
  ) {
    return GestureDetector(
      onTap: () => _showStatusPicker(context, myUid), // Tıklayınca menü açılır
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Durumum", // Başlık
                  style: GoogleFonts.kadwa(fontSize: 14, color: secondaryText),
                ),
                // İkon Mavi (Kendin olduğunu belirtmek için)
                const Icon(Icons.face, size: 18, color: Colors.blueAccent),
              ],
            ),
            Center(child: Text(myIcon, style: const TextStyle(fontSize: 32))),
            Center(
              child: Text(
                myText,
                style: GoogleFonts.kadwa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Center(
              child: Text(
                "(Değiştirmek için tıkla)",
                style: GoogleFonts.kadwa(fontSize: 10, color: secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DURUM MENÜSÜ ---
  void _showStatusPicker(BuildContext context, String myUid) {
    TextEditingController customStatusController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Durumunu Güncelle",
                style: GoogleFonts.kadwa(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _statusButton(context, myUid, "☕", "Kahve"),
                  _statusButton(context, myUid, "💻", "İş"),
                  _statusButton(context, myUid, "🚗", "Yol"),
                  _statusButton(context, myUid, "❤️", "Aşk"),
                  _statusButton(context, myUid, "🏠", "Ev"),
                  _statusButton(context, myUid, "💤", "Uyku"),
                ],
              ),
              const SizedBox(height: 25),
              Divider(color: Colors.grey[200]),
              const SizedBox(height: 15),
              Text(
                "Veya kendin yaz:",
                style: GoogleFonts.kadwa(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customStatusController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: "Örn: Çok yorgunum...",
                        hintStyle: GoogleFonts.kadwa(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        counterText: "",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      String text = customStatusController.text.trim();
                      if (text.isNotEmpty) {
                        // 1. Veritabanına Yaz
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(myUid)
                            .set({
                              'statusIcon': "💬",
                              'statusText': text,
                              'lastUpdated': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                        // 2. === BİLDİRİM GÖNDER ===
                        _notifyPartner(myUid, "💬", text);

                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2342),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // --- İKONLU BUTON ---
  Widget _statusButton(
    BuildContext context,
    String myUid,
    String icon,
    String text,
  ) {
    return GestureDetector(
      onTap: () {
        // 1. Veritabanına Yaz
        FirebaseFirestore.instance.collection('users').doc(myUid).set({
          'statusIcon': icon,
          'statusText': text,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 2. === BİLDİRİM GÖNDER ===
        _notifyPartner(myUid, icon, text);

        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: GoogleFonts.kadwa(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // === PARTNERE BİLDİRİM GÖNDEREN FONKSİYON ===
  Future<void> _notifyPartner(String myUid, String icon, String text) async {
    try {
      // 1. Eşimin ID'sini bul
      DocumentSnapshot myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .get();

      String? partnerId = myDoc.get('pairedWith');
      if (partnerId == null) return;

      // 2. Eşimin Cihaz Token'ını bul
      DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(partnerId)
          .get();

      var partnerData = partnerDoc.data() as Map<String, dynamic>?;
      String? token = partnerData?['fcmToken'];

      if (token == null) return;

      // 3. Bildirimi Ateşle
      String serverKey =
          'AIzaSyBcA32H_ytMwdX1qCfxN5eIBw7v86KKkiY'; // FCM Server Key

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'title': 'Partnerinden Durum: $icon',
            'body': text,
            'sound': 'default',
          },
          'to': token,
        }),
      );
    } catch (e) {
      print("Bildirim hatası: $e");
    }
  }
}
