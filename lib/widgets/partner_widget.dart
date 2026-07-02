import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ozet_app/screens/settings_screen.dart';
import 'package:ozet_app/widgets/app_feedback.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PartnerWidget extends StatefulWidget {
  const PartnerWidget({Key? key}) : super(key: key);

  @override
  State<PartnerWidget> createState() => _PartnerWidgetState();
}

class _PartnerWidgetState extends State<PartnerWidget> {
  static const int _maxPartnerShares = 3;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackgroundColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final Color primaryTextColor = isDark ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDark
        ? Colors.grey[400]!
        : Colors.black54;
    final Color borderColor = isDark
        ? Colors.grey[850]!
        : const Color(0xFFE9EEF4);

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

    if (user == null) {
      return _buildCardShell(
        cardBackgroundColor: cardBackgroundColor,
        borderColor: borderColor,
        accentColor: Colors.teal,
        isDark: isDark,
        child: _buildDetoxPage(
          context,
          Colors.teal,
          primaryTextColor,
          secondaryTextColor,
          fallbackNewsCount: 5,
        ),
      );
    }

    return _buildCardShell(
      cardBackgroundColor: cardBackgroundColor,
      borderColor: borderColor,
      accentColor: themeColor,
      isDark: isDark,
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
    );
  }

  // Ana sayfadaki detoks/eslesme kartlari icin ortak, sakin kart kabugu.
  Widget _buildCardShell({
    required Widget child,
    required Color cardBackgroundColor,
    required Color borderColor,
    required Color accentColor,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : accentColor.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
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
        final savedMinutes = newsCount * 4;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderRow(
                title: "Detoks",
                secondaryText: secondaryText,
                accentColor: themeColor,
                icon: Icons.spa_outlined,
                activeIndex: FirebaseAuth.instance.currentUser == null
                    ? null
                    : 0,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$savedMinutes dk",
                    style: GoogleFonts.kadwa(
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color: themeColor.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "kazandığın süre",
                    style: GoogleFonts.kadwa(
                      fontSize: 11,
                      color: secondaryText,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "$newsCount özet okundu",
                      style: GoogleFonts.kadwa(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: secondaryText),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniIcon(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildActionHint(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.kadwa(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  IconData? _statusIconData(String key) {
    return switch (key) {
      'calm' => Icons.self_improvement_outlined,
      'chat' => Icons.chat_bubble_outline,
      'soon' => Icons.schedule_outlined,
      'busy' => Icons.work_outline,
      'coffee' => Icons.local_cafe_outlined,
      'thinking' => Icons.favorite_border,
      'rest' => Icons.bedtime_outlined,
      'good' => Icons.check_circle_outline,
      'custom' => Icons.edit_note_outlined,
      'note' => Icons.mail_outline,
      'sketch' => Icons.draw_outlined,
      _ => null,
    };
  }

  Widget _buildStatusMark(String key, Color color, {double size = 22}) {
    final iconData = _statusIconData(key);
    if (iconData != null) {
      return Icon(iconData, size: size, color: color);
    }

    return Text(key, style: TextStyle(fontSize: size));
  }

  Widget _buildStatusBubble(String icon, Color color, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: _buildStatusMark(icon, color, size: size * 0.52),
    );
  }

  Widget _buildTinyDots(int activeIndex, Color activeColor, Color mutedColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(left: 3),
          width: isActive ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? activeColor : mutedColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderRow({
    required String title,
    required Color secondaryText,
    required Color accentColor,
    required IconData icon,
    int? activeIndex,
    bool hasIndicator = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.kadwa(fontSize: 14, color: secondaryText),
            ),
            if (hasIndicator) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        Row(
          children: [
            if (activeIndex != null) ...[
              _buildTinyDots(activeIndex, accentColor, secondaryText),
              const SizedBox(width: 7),
            ],
            _buildMiniIcon(icon, accentColor),
          ],
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderRow(
              title: "Eşleşme",
              secondaryText: secondaryText,
              accentColor: Colors.redAccent,
              icon: Icons.link,
              activeIndex: 1,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Partner yok",
                  style: GoogleFonts.kadwa(
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Durum paylaşmak için bağlan.",
                  style: GoogleFonts.kadwa(
                    fontSize: 11,
                    color: secondaryText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionHint("Ayarlar", Colors.redAccent),
                Icon(Icons.arrow_forward_ios, size: 12, color: secondaryText),
              ],
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
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final icon = data?['statusIcon'] as String? ?? "👋";
        final text = data?['statusText'] as String? ?? "Müsait";
        final noteText = (data?['partnerNote'] as String?)?.trim();
        final sketchStrokes = _readSketchStrokes(data?['partnerSketch']);
        final hasNote = noteText != null && noteText.isNotEmpty;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showPartnerSharesSheet(context, partnerId),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(
                  title: "Partner",
                  secondaryText: secondaryText,
                  accentColor: Colors.redAccent,
                  icon: Icons.favorite_border,
                  activeIndex: 1,
                  hasIndicator: hasNote,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: sketchStrokes.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: secondaryText.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: secondaryText.withValues(alpha: 0.10),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CustomPaint(
                              painter: _SketchPainter(sketchStrokes),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.draw_outlined,
                            size: 26,
                            color: Colors.redAccent.withValues(alpha: 0.72),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusBubble(icon, Colors.redAccent, size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.kadwa(
                          fontSize: 13,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: secondaryText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPartnerSharesSheet(BuildContext context, String partnerId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF262626) : const Color(0xFFF6F8FA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDark ? Colors.grey[850]! : const Color(0xFFE9EEF4);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(partnerId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final shares = _partnerSharesFromData(data);
          final noteText = (data?['partnerNote'] as String?)?.trim();
          final sketchStrokes = _readSketchStrokes(data?['partnerSketch']);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: mutedColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Partner paylaşımı",
                  style: GoogleFonts.kadwa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Son 3 durum, not veya çizim burada görünür.",
                  style: GoogleFonts.kadwa(
                    fontSize: 13,
                    color: mutedColor,
                    height: 1.25,
                  ),
                ),
                if (sketchStrokes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1.8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: _SketchPainter(sketchStrokes),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ],
                if (noteText != null && noteText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      noteText,
                      style: GoogleFonts.kadwa(
                        fontSize: 13,
                        color: textColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  "Son paylaşımlar",
                  style: GoogleFonts.kadwa(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (shares.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      "Henüz paylaşım yok.",
                      style: GoogleFonts.kadwa(
                        fontSize: 12,
                        color: mutedColor,
                        height: 1.2,
                      ),
                    ),
                  )
                else
                  ...shares.map(
                    (share) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildPartnerShareCard(
                        share: share,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        inputBg: inputBg,
                        borderColor: borderColor,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartnerShareCard({
    required _PartnerShare share,
    required Color textColor,
    required Color mutedColor,
    required Color inputBg,
    required Color borderColor,
  }) {
    final icon = switch (share.type) {
      'sketch' => Icons.draw_outlined,
      'note' => Icons.mail_outline,
      _ => Icons.radio_button_checked,
    };
    final title = switch (share.type) {
      'sketch' => 'Çizim',
      'note' => 'Mini not',
      _ => 'Durum',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: mutedColor),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kadwa(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                if (share.type == 'sketch' && share.strokes.isNotEmpty)
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: mutedColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _SketchPainter(share.strokes),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      if (share.icon != null) ...[
                        _buildStatusMark(share.icon!, mutedColor, size: 15),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          share.text ?? '',
                          style: GoogleFonts.kadwa(
                            fontSize: 12,
                            color: mutedColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_PartnerShare> _partnerSharesFromData(Map<String, dynamic>? data) {
    final shares = _readPartnerShares(data?['partnerShares']);
    if (shares.isNotEmpty) return shares.take(_maxPartnerShares).toList();

    final fallback = <_PartnerShare>[];
    final sketchStrokes = _readSketchStrokes(data?['partnerSketch']);
    final noteText = (data?['partnerNote'] as String?)?.trim();
    final statusText = (data?['statusText'] as String?)?.trim();
    final statusIcon = data?['statusIcon'] as String?;

    if (sketchStrokes.isNotEmpty) {
      fallback.add(_PartnerShare(type: 'sketch', strokes: sketchStrokes));
    }
    if (noteText != null && noteText.isNotEmpty) {
      fallback.add(_PartnerShare(type: 'note', text: noteText));
    }
    if (statusText != null && statusText.isNotEmpty) {
      fallback.add(
        _PartnerShare(type: 'status', text: statusText, icon: statusIcon),
      );
    }

    return fallback.take(_maxPartnerShares).toList();
  }

  List<_PartnerShare> _readPartnerShares(dynamic rawShares) {
    if (rawShares is! List) return [];

    return rawShares
        .whereType<Map>()
        .map((share) => _PartnerShare.fromJson(share))
        .where((share) => share.isVisible)
        .take(_maxPartnerShares)
        .toList();
  }

  List<_SketchStroke> _readSketchStrokes(dynamic sketchData) {
    if (sketchData is! Map<String, dynamic>) return [];
    final rawStrokes = sketchData['strokes'];
    if (rawStrokes is! List) return [];

    return rawStrokes
        .whereType<Map>()
        .map((stroke) => _SketchStroke.fromJson(stroke))
        .where((stroke) => stroke.points.isNotEmpty)
        .toList();
  }

  void _showSketchPreview(BuildContext context, List<_SketchStroke> strokes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _SketchPainter(strokes),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderRow(
              title: "Durumum",
              secondaryText: secondaryText,
              accentColor: Colors.blueAccent,
              icon: Icons.face_outlined,
              activeIndex: 2,
            ),
            Row(
              children: [
                _buildStatusBubble(myIcon, Colors.blueAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    myText,
                    style: GoogleFonts.kadwa(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionHint("Güncelle", Colors.blueAccent),
                Icon(Icons.touch_app_outlined, size: 15, color: secondaryText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DURUM MENÜSÜ ---
  void _showStatusPicker(BuildContext context, String myUid) {
    final parentContext = context;
    final customStatusController = TextEditingController();
    final noteController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF262626) : const Color(0xFFF6F8FA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDark ? Colors.grey[850]! : const Color(0xFFE9EEF4);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Durumunu güncelle",
                style: GoogleFonts.kadwa(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                "Hızlı his seç veya partnerine kısa bir not bırak.",
                style: GoogleFonts.kadwa(
                  fontSize: 13,
                  color: mutedColor,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 18),
              _buildSharedItemsSection(
                myUid: myUid,
                textColor: textColor,
                mutedColor: mutedColor,
                inputBg: inputBg,
                borderColor: borderColor,
                feedbackContext: parentContext,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _statusButton(
                      context,
                      parentContext,
                      myUid,
                      "calm",
                      "Sakinim",
                      inputBg,
                      textColor,
                      borderColor,
                    ),
                    _statusButton(
                      context,
                      parentContext,
                      myUid,
                      "chat",
                      "Konuşalım",
                      inputBg,
                      textColor,
                      borderColor,
                    ),
                    _statusButton(
                      context,
                      parentContext,
                      myUid,
                      "soon",
                      "Birazdan",
                      inputBg,
                      textColor,
                      borderColor,
                    ),
                    _statusButton(
                      context,
                      parentContext,
                      myUid,
                      "busy",
                      "Yoğunum",
                      inputBg,
                      textColor,
                      borderColor,
                    ),
                    _statusButton(
                      context,
                      parentContext,
                      myUid,
                      "coffee",
                      "Kahve",
                      inputBg,
                      textColor,
                      borderColor,
                    ),
                    _statusButton(
                      context,
                      parentContext,
                      myUid,
                      "thinking",
                      "Seni düşünüyorum",
                      inputBg,
                      textColor,
                      borderColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Özel durum",
                style: GoogleFonts.kadwa(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customStatusController,
                      maxLength: 28,
                      style: GoogleFonts.kadwa(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Örn: Biraz yorgunum",
                        hintStyle: GoogleFonts.kadwa(
                          fontSize: 14,
                          color: mutedColor,
                        ),
                        counterText: "",
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final nav = Navigator.of(context);
                      String text = customStatusController.text.trim();
                      if (text.isNotEmpty) {
                        try {
                          await _updateStatus(myUid, "custom", text);
                          _notifyPartner(myUid, "custom", text);
                          nav.pop();
                          if (parentContext.mounted) {
                            AppFeedback.show(
                              parentContext,
                              "Durum güncellendi.",
                              type: AppFeedbackType.success,
                            );
                          }
                        } catch (_) {
                          if (parentContext.mounted) {
                            AppFeedback.show(
                              parentContext,
                              "Durum güncellenemedi.",
                              type: AppFeedbackType.error,
                            );
                          }
                        }
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
              const SizedBox(height: 18),
              Divider(color: borderColor),
              const SizedBox(height: 14),
              Text(
                "Mini not",
                style: GoogleFonts.kadwa(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLength: 80,
                minLines: 2,
                maxLines: 3,
                style: GoogleFonts.kadwa(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Partnerinin kartında görünecek kısa bir not yaz.",
                  hintStyle: GoogleFonts.kadwa(fontSize: 13, color: mutedColor),
                  counterStyle: GoogleFonts.kadwa(
                    fontSize: 11,
                    color: mutedColor,
                  ),
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final note = noteController.text.trim();
                    if (note.isEmpty) return;
                    try {
                      await _sendPartnerNote(myUid, note);
                      nav.pop();
                      if (parentContext.mounted) {
                        AppFeedback.show(
                          parentContext,
                          "Mini not gönderildi.",
                          type: AppFeedbackType.success,
                        );
                      }
                    } catch (_) {
                      if (parentContext.mounted) {
                        AppFeedback.show(
                          parentContext,
                          "Mini not gönderilemedi.",
                          type: AppFeedbackType.error,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: Text(
                    "Notu gönder",
                    style: GoogleFonts.kadwa(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2342),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSketchComposer(parentContext, myUid);
                  },
                  icon: const Icon(Icons.draw_outlined, size: 18),
                  label: Text(
                    "Çizim gönder",
                    style: GoogleFonts.kadwa(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharedItemsSection({
    required String myUid,
    required Color textColor,
    required Color mutedColor,
    required Color inputBg,
    required Color borderColor,
    required BuildContext feedbackContext,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final noteText = (data?['partnerNote'] as String?)?.trim();
        final sketchStrokes = _readSketchStrokes(data?['partnerSketch']);
        final hasNote = noteText != null && noteText.isNotEmpty;
        final hasSketch = sketchStrokes.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Paylaştıkların",
              style: GoogleFonts.kadwa(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasNote && !hasSketch)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  "Henüz paylaştığın bir not veya çizim yok.",
                  style: GoogleFonts.kadwa(
                    fontSize: 12,
                    color: mutedColor,
                    height: 1.2,
                  ),
                ),
              ),
            if (hasNote)
              _buildSharedItemCard(
                title: "Mini not",
                icon: Icons.mail_outline,
                textColor: textColor,
                mutedColor: mutedColor,
                inputBg: inputBg,
                borderColor: borderColor,
                onDelete: () async {
                  final confirmed = await _confirmSharedItemDelete(
                    feedbackContext,
                    "Mini not silinsin mi?",
                    "Bu not partner kartından kaldırılacak.",
                  );
                  if (!confirmed) return;
                  try {
                    await _deletePartnerNote(myUid);
                    if (feedbackContext.mounted) {
                      AppFeedback.show(
                        feedbackContext,
                        "Mini not silindi.",
                        type: AppFeedbackType.success,
                      );
                    }
                  } catch (_) {
                    if (feedbackContext.mounted) {
                      AppFeedback.show(
                        feedbackContext,
                        "Mini not silinemedi.",
                        type: AppFeedbackType.error,
                      );
                    }
                  }
                },
                child: Text(
                  noteText,
                  style: GoogleFonts.kadwa(
                    fontSize: 12,
                    color: mutedColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (hasNote && hasSketch) const SizedBox(height: 8),
            if (hasSketch)
              _buildSharedItemCard(
                title: "Çizim",
                icon: Icons.draw_outlined,
                textColor: textColor,
                mutedColor: mutedColor,
                inputBg: inputBg,
                borderColor: borderColor,
                onDelete: () async {
                  final confirmed = await _confirmSharedItemDelete(
                    feedbackContext,
                    "Çizim silinsin mi?",
                    "Bu çizim partner kartından kaldırılacak.",
                  );
                  if (!confirmed) return;
                  try {
                    await _deletePartnerSketch(myUid);
                    if (feedbackContext.mounted) {
                      AppFeedback.show(
                        feedbackContext,
                        "Çizim silindi.",
                        type: AppFeedbackType.success,
                      );
                    }
                  } catch (_) {
                    if (feedbackContext.mounted) {
                      AppFeedback.show(
                        feedbackContext,
                        "Çizim silinemedi.",
                        type: AppFeedbackType.error,
                      );
                    }
                  }
                },
                child: GestureDetector(
                  onTap: () => _showSketchPreview(context, sketchStrokes),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: mutedColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _SketchPainter(sketchStrokes),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmSharedItemDelete(
    BuildContext context,
    String title,
    String message,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.kadwa(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.kadwa(
            color: mutedColor,
            fontSize: 14,
            height: 1.3,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Vazgeç",
              style: GoogleFonts.kadwa(
                color: mutedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE57373).withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Sil",
              style: GoogleFonts.kadwa(
                color: const Color(0xFFE57373),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result == true;
  }

  Widget _buildSharedItemCard({
    required String title,
    required IconData icon,
    required Widget child,
    required Color textColor,
    required Color mutedColor,
    required Color inputBg,
    required Color borderColor,
    required Future<void> Function() onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 9, 11),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: mutedColor),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kadwa(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                child,
              ],
            ),
          ),
          IconButton(
            tooltip: "$title sil",
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 19),
            color: mutedColor,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
    );
  }

  // --- İKONLU BUTON ---
  Widget _statusButton(
    BuildContext context,
    BuildContext feedbackContext,
    String myUid,
    String icon,
    String text,
    Color bgColor,
    Color textColor,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () async {
        final nav = Navigator.of(context);
        try {
          await _updateStatus(myUid, icon, text);
          _notifyPartner(myUid, icon, text);
          nav.pop();
          if (feedbackContext.mounted) {
            AppFeedback.show(
              feedbackContext,
              "Durum güncellendi.",
              type: AppFeedbackType.success,
            );
          }
        } catch (_) {
          if (feedbackContext.mounted) {
            AppFeedback.show(
              feedbackContext,
              "Durum güncellenemedi.",
              type: AppFeedbackType.error,
            );
          }
        }
      },
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusMark(icon, textColor, size: 18),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 122),
              child: Text(
                text,
                style: GoogleFonts.kadwa(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String myUid, String icon, String text) async {
    await _savePartnerShare(
      myUid,
      latestFields: {
        'statusIcon': icon,
        'statusText': text,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      share: {
        'id': _newShareId(),
        'type': 'status',
        'icon': icon,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _sendPartnerNote(String myUid, String note) async {
    await _savePartnerShare(
      myUid,
      latestFields: {
        'partnerNote': note,
        'partnerNoteUpdatedAt': FieldValue.serverTimestamp(),
      },
      share: {
        'id': _newShareId(),
        'type': 'note',
        'text': note,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );

    _notifyPartner(myUid, "note", note);
  }

  Future<void> _deletePartnerNote(String myUid) async {
    await _deletePartnerShareType(myUid, 'note', {
      'partnerNote': FieldValue.delete(),
      'partnerNoteUpdatedAt': FieldValue.delete(),
    });
  }

  Future<void> _savePartnerShare(
    String myUid, {
    required Map<String, dynamic> latestFields,
    required Map<String, dynamic> share,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(myUid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data();
      final existing =
          (data?['partnerShares'] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          <Map<String, dynamic>>[];

      transaction.set(docRef, {
        ...latestFields,
        'partnerShares': [share, ...existing].take(_maxPartnerShares).toList(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _deletePartnerShareType(
    String myUid,
    String type,
    Map<String, dynamic> fieldsToDelete,
  ) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(myUid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data();
      final existing =
          (data?['partnerShares'] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['type'] != type)
              .take(_maxPartnerShares)
              .toList() ??
          <Map<String, dynamic>>[];

      transaction.set(docRef, {
        ...fieldsToDelete,
        'partnerShares': existing,
      }, SetOptions(merge: true));
    });
  }

  String _newShareId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _showSketchComposer(BuildContext context, String myUid) {
    final feedbackContext = context;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _SketchComposer(
          textColor: textColor,
          mutedColor: mutedColor,
          onSend: (strokes) async {
            final nav = Navigator.of(context);
            try {
              await _sendPartnerSketch(myUid, strokes);
              nav.pop();
              if (feedbackContext.mounted) {
                AppFeedback.show(
                  feedbackContext,
                  "Çizim gönderildi.",
                  type: AppFeedbackType.success,
                );
              }
            } catch (_) {
              if (feedbackContext.mounted) {
                AppFeedback.show(
                  feedbackContext,
                  "Çizim gönderilemedi.",
                  type: AppFeedbackType.error,
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _sendPartnerSketch(
    String myUid,
    List<_SketchStroke> strokes,
  ) async {
    if (strokes.isEmpty) return;

    final serializedStrokes = strokes.map((stroke) => stroke.toJson()).toList();
    await _savePartnerShare(
      myUid,
      latestFields: {
        'partnerSketch': {
          'strokes': serializedStrokes,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      share: {
        'id': _newShareId(),
        'type': 'sketch',
        'strokes': serializedStrokes,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );

    _notifyPartner(myUid, "sketch", "Sana bir çizim gönderdi.");
  }

  Future<void> _deletePartnerSketch(String myUid) async {
    await _deletePartnerShareType(myUid, 'sketch', {
      'partnerSketch': FieldValue.delete(),
    });
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
            'title': 'Partnerinden durum',
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

class _PartnerShare {
  const _PartnerShare({
    required this.type,
    this.text,
    this.icon,
    this.strokes = const [],
  });

  final String type;
  final String? text;
  final String? icon;
  final List<_SketchStroke> strokes;

  bool get isVisible {
    if (type == 'sketch') return strokes.isNotEmpty;
    return text != null && text!.trim().isNotEmpty;
  }

  factory _PartnerShare.fromJson(Map<dynamic, dynamic> json) {
    final type = json['type'] as String? ?? 'status';
    final rawStrokes = json['strokes'];

    return _PartnerShare(
      type: type,
      text: (json['text'] as String?)?.trim(),
      icon: json['icon'] as String?,
      strokes: rawStrokes is List
          ? rawStrokes
                .whereType<Map>()
                .map((stroke) => _SketchStroke.fromJson(stroke))
                .where((stroke) => stroke.points.isNotEmpty)
                .toList()
          : [],
    );
  }
}

class _SketchComposer extends StatefulWidget {
  const _SketchComposer({
    required this.textColor,
    required this.mutedColor,
    required this.onSend,
  });

  final Color textColor;
  final Color mutedColor;
  final Future<void> Function(List<_SketchStroke> strokes) onSend;

  @override
  State<_SketchComposer> createState() => _SketchComposerState();
}

class _SketchComposerState extends State<_SketchComposer> {
  final List<_SketchStroke> _strokes = [];
  Color _selectedColor = const Color(0xFF0A2342);
  bool _isSending = false;

  void _startStroke(Offset localPosition, Size size) {
    setState(() {
      _strokes.add(
        _SketchStroke(
          colorValue: _selectedColor.toARGB32(),
          width: 4,
          points: [_normalize(localPosition, size)],
        ),
      );
    });
  }

  void _extendStroke(Offset localPosition, Size size) {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.last.points.add(_normalize(localPosition, size));
    });
  }

  Offset _normalize(Offset point, Size size) {
    final safeWidth = size.width == 0 ? 1.0 : size.width;
    final safeHeight = size.height == 0 ? 1.0 : size.height;

    return Offset(
      (point.dx / safeWidth).clamp(0.0, 1.0),
      (point.dy / safeHeight).clamp(0.0, 1.0),
    );
  }

  Future<void> _send() async {
    if (_strokes.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    await widget.onSend(_strokes);
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF262626) : const Color(0xFFF6F8FA);
    final borderColor = isDark ? Colors.grey[850]! : const Color(0xFFE9EEF4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: widget.mutedColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Çizim gönder",
          style: GoogleFonts.kadwa(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
          ),
        ),
        Text(
          "Küçük bir çizim bırak; partner kartında görünsün.",
          style: GoogleFonts.kadwa(
            fontSize: 13,
            color: widget.mutedColor,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return GestureDetector(
                onPanStart: (details) =>
                    _startStroke(details.localPosition, canvasSize),
                onPanUpdate: (details) =>
                    _extendStroke(details.localPosition, canvasSize),
                child: Container(
                  decoration: BoxDecoration(
                    color: canvasBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(
                      painter: _SketchPainter(_strokes),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _colorButton(const Color(0xFF0A2342)),
            _colorButton(const Color(0xFF1F91DC)),
            _colorButton(const Color(0xFFE57373)),
            _colorButton(const Color(0xFF2E7D32)),
            const Spacer(),
            IconButton(
              tooltip: "Geri al",
              onPressed: _strokes.isEmpty
                  ? null
                  : () => setState(() => _strokes.removeLast()),
              icon: const Icon(Icons.undo),
              color: widget.textColor,
            ),
            IconButton(
              tooltip: "Temizle",
              onPressed: _strokes.isEmpty
                  ? null
                  : () => setState(_strokes.clear),
              icon: const Icon(Icons.delete_outline),
              color: widget.textColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _strokes.isEmpty || _isSending ? null : _send,
            icon: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(
              "Çizimi gönder",
              style: GoogleFonts.kadwa(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2342),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFF0A2342,
              ).withValues(alpha: 0.45),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorButton(Color color) {
    final selected = _selectedColor == color;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedColor = color),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? widget.textColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SketchStroke {
  _SketchStroke({
    required this.colorValue,
    required this.width,
    required this.points,
  });

  final int colorValue;
  final double width;
  final List<Offset> points;

  factory _SketchStroke.fromJson(Map<dynamic, dynamic> json) {
    final rawPoints = json['points'];

    return _SketchStroke(
      colorValue: (json['color'] as num?)?.toInt() ?? 0xFF0A2342,
      width: (json['width'] as num?)?.toDouble() ?? 4,
      points: rawPoints is List
          ? rawPoints
                .whereType<Map>()
                .map(
                  (point) => Offset(
                    ((point['x'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
                    ((point['y'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
                  ),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': colorValue,
      'width': width,
      'points': points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
    };
  }
}

class _SketchPainter extends CustomPainter {
  const _SketchPainter(this.strokes);

  final List<_SketchStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final first = stroke.points.first;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(first.dx * size.width, first.dy * size.height),
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }

      path.moveTo(first.dx * size.width, first.dy * size.height);

      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) {
    return true;
  }
}
