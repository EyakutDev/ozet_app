import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:ozet_app/core/errors/app_error_handler.dart';
import 'package:ozet_app/models/partner_status_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ozet_app/screens/settings_screen.dart';
import 'package:ozet_app/widgets/app_feedback.dart';
import 'package:ozet_app/widgets/home_panel_controls.dart';
import 'dart:ui' show ImageFilter;

Future<void> _showPartnerFailure(
  BuildContext context,
  Object error,
  StackTrace stackTrace, {
  required String operation,
  required String fallbackMessage,
  VoidCallback? onRetry,
}) async {
  final failure = await AppErrorHandler.capture(
    error,
    stackTrace,
    operation: operation,
    fallbackMessage: fallbackMessage,
  );
  if (!context.mounted) return;
  AppFeedback.showFailure(context, failure, onRetry: onRetry);
}

class PartnerWidget extends StatefulWidget {
  const PartnerWidget({
    super.key,
    required this.cardColor,
    this.embedded = false,
  });

  final Color cardColor;
  final bool embedded;

  @override
  State<PartnerWidget> createState() => _PartnerWidgetState();
}

class _PartnerWidgetState extends State<PartnerWidget> {
  static const int _maxPartnerShares = 3;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackgroundColor = widget.cardColor;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.black54;
    final borderColor = isDark ? Colors.grey[850]! : const Color(0xFFE9EEF4);
    final themeColor = _neutralAccent(context);

    if (user == null) {
      return _buildCardShell(
        cardBackgroundColor: cardBackgroundColor,
        borderColor: borderColor,
        accentColor: _neutralAccent(context),
        isDark: isDark,
        child: _buildConnectPage(
          context,
          primaryTextColor,
          secondaryTextColor,
          activeIndex: null,
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

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final partnerId = userData?['pairedWith'] as String?;
          final myStatus = PartnerStatusView.fromData(
            userData,
            fallbackText: 'Durum ayarla',
          );
          final myIcon = myStatus.icon;
          final myText = myStatus.text;

          return PageView(
            scrollDirection: Axis.horizontal,
            children: [
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

  // Ana partner kartlarinda acik ve koyu tema icin notr kontrast kullanilir.
  Color _neutralAccent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFF5F5F5) : const Color(0xFF111111);
  }

  // Ana sayfadaki partner kartlari icin ortak, sakin kart kabugu.
  Widget _buildCardShell({
    required Widget child,
    required Color cardBackgroundColor,
    required Color borderColor,
    required Color accentColor,
    required bool isDark,
  }) {
    if (widget.embedded) return child;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: _neutralAccent(context),
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildMiniIcon(IconData icon, Color color) {
    return HomePanelIcon(icon: icon, foregroundColor: color);
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

  Widget _buildHeaderRow({
    required String title,
    required Color secondaryText,
    required Color accentColor,
    required IconData icon,
    bool hasIndicator = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
              if (hasIndicator) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildMiniIcon(icon, accentColor),
      ],
    );
  }

  // --- BAĞLANMA EKRANI ---
  Widget _buildConnectPage(
    BuildContext context,
    Color primaryText,
    Color secondaryText, {
    int? activeIndex = 0,
  }) {
    final accentColor = _neutralAccent(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(
              title: "Eşleşme",
              secondaryText: secondaryText,
              accentColor: accentColor,
              icon: Icons.link_rounded,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Eşleşme yok",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            HomePanelFooter(
              activeIndex: activeIndex,
              foregroundColor: accentColor,
              mutedColor: secondaryText,
              actionLabel: "Eşleştir",
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
        final status = PartnerStatusView.fromData(data);
        final icon = status.icon;
        final text = status.text;
        final noteText = (data?['partnerNote'] as String?)?.trim();
        final sketchStrokes = _readSketchStrokes(data?['partnerSketch']);
        final hasNote = noteText != null && noteText.isNotEmpty;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accentColor = _neutralAccent(context);
        final previewSurface = isDark
            ? const Color(0xFFF5F5F7).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.52);
        final previewBorder = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.045);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showPartnerSharesSheet(context, partnerId),
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(
                  title: "Partner",
                  secondaryText: secondaryText,
                  accentColor: accentColor,
                  icon: Icons.person_outline_rounded,
                  hasIndicator: hasNote,
                ),
                const SizedBox(height: 7),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: sketchStrokes.isNotEmpty
                          ? previewSurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: previewBorder),
                    ),
                    child: sketchStrokes.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: CustomPaint(
                              painter: _SketchPainter(
                                sketchStrokes,
                                fitToContent: true,
                                previewPadding: 5,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.draw_outlined,
                              size: 24,
                              color: accentColor.withValues(alpha: 0.58),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 7),
                HomePanelFooter(
                  activeIndex: 0,
                  foregroundColor: accentColor,
                  mutedColor: secondaryText,
                  leading: Row(
                    children: [
                      SizedBox.square(
                        dimension: 18,
                        child: Center(
                          child: _buildStatusMark(
                            icon,
                            accentColor.withValues(alpha: 0.82),
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                          painter: _SketchPainter(
                            sketchStrokes,
                            fitToContent: true,
                            previewPadding: 12,
                          ),
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
                        painter: _SketchPainter(
                          share.strokes,
                          fitToContent: true,
                          previewPadding: 8,
                        ),
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
    final accentColor = _neutralAccent(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showStatusPicker(context, myUid),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(
              title: "Durumum",
              secondaryText: secondaryText,
              accentColor: accentColor,
              icon: Icons.face_outlined,
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 25,
                    child: Center(
                      child: _buildStatusMark(
                        myIcon,
                        accentColor.withValues(alpha: 0.82),
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      myText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                        letterSpacing: 0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            HomePanelFooter(
              activeIndex: 1,
              foregroundColor: accentColor,
              mutedColor: secondaryText,
              actionLabel: "Güncelle",
            ),
          ],
        ),
      ),
    );
  }

  // --- DURUM MENÜSÜ ---
  Future<void> _showStatusPicker(BuildContext context, String myUid) async {
    final parentContext = context;
    final customStatusController = TextEditingController();
    final noteController = TextEditingController();
    BuildContext? activeSheetContext;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.of(context).highContrast;
    final glassTint = isDark
        ? const Color(0xFF141416).withValues(alpha: highContrast ? 0.96 : 0.82)
        : Colors.white.withValues(alpha: highContrast ? 0.97 : 0.78);
    final controlSurface = isDark
        ? Colors.white.withValues(alpha: highContrast ? 0.14 : 0.08)
        : Colors.white.withValues(alpha: highContrast ? 0.92 : 0.58);
    final inputSurface = isDark
        ? Colors.white.withValues(alpha: highContrast ? 0.13 : 0.075)
        : const Color(0xFFF2F2F7).withValues(alpha: highContrast ? 0.96 : 0.78);
    final textColor = isDark
        ? const Color(0xFFF5F5F7)
        : const Color(0xFF111114);
    final mutedColor = isDark
        ? const Color(0xFFA1A1A6)
        : const Color(0xFF6E6E73);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.88);
    final controlBorder = isDark
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.black.withValues(alpha: 0.065);
    final focusedBorder = textColor.withValues(alpha: isDark ? 0.42 : 0.28);
    final actionBackground = _neutralAccent(context);
    final actionForeground = isDark ? const Color(0xFF111114) : Colors.white;
    final sectionLabelStyle = GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: mutedColor,
      letterSpacing: 0,
      height: 1.1,
    );

    Widget buildComposerAction({
      required bool enabled,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        opacity: enabled ? 1 : 0.42,
        child: IconButton(
          tooltip: tooltip,
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.arrow_upward_rounded, size: 19),
          style: IconButton.styleFrom(
            foregroundColor: actionForeground,
            backgroundColor: actionBackground,
            disabledForegroundColor: mutedColor,
            disabledBackgroundColor: mutedColor.withValues(alpha: 0.12),
            fixedSize: const Size.square(36),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
        ),
      );
    }

    Future<void> submitCustomStatus(BuildContext sheetContext) async {
      final text = customStatusController.text.trim();
      if (text.isEmpty) return;

      final nav = Navigator.of(sheetContext);
      try {
        await _updateStatus(myUid, "custom", text);
        _notifyPartner("custom", text);
        if (sheetContext.mounted) nav.pop();
        if (parentContext.mounted) {
          AppFeedback.show(
            parentContext,
            "Durum güncellendi.",
            type: AppFeedbackType.success,
          );
        }
      } catch (error, stackTrace) {
        if (!parentContext.mounted) return;
        await _showPartnerFailure(
          parentContext,
          error,
          stackTrace,
          operation: 'partner.update_custom_status',
          fallbackMessage: 'Durum güncellenemedi.',
          onRetry: () => submitCustomStatus(sheetContext),
        );
      }
    }

    Future<void> submitNote(BuildContext sheetContext) async {
      final note = noteController.text.trim();
      if (note.isEmpty) return;

      final nav = Navigator.of(sheetContext);
      try {
        await _sendPartnerNote(myUid, note);
        if (sheetContext.mounted) nav.pop();
        if (parentContext.mounted) {
          AppFeedback.show(
            parentContext,
            "Mini not gönderildi.",
            type: AppFeedbackType.success,
          );
        }
      } catch (error, stackTrace) {
        if (!parentContext.mounted) return;
        await _showPartnerFailure(
          parentContext,
          error,
          stackTrace,
          operation: 'partner.send_note',
          fallbackMessage: 'Mini not gönderilemedi.',
          onRetry: () => submitNote(sheetContext),
        );
      }
    }

    // Cam efekti tek katmanda tutulur; alt kontroller tekrar blur edilmez.
    final openSketch = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.26),
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) {
        activeSheetContext = sheetContext;
        final mediaQuery = MediaQuery.of(sheetContext);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                blurRadius: 34,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: glassTint,
                  border: Border.all(color: glassBorder),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    mediaQuery.viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: textColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Durumunu güncelle",
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    letterSpacing: 0,
                                    height: 1.12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Partnerinle ne paylaşmak istersin?",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: mutedColor,
                                    letterSpacing: 0,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: "Kapat",
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded, size: 19),
                            style: IconButton.styleFrom(
                              foregroundColor: textColor,
                              backgroundColor: controlSurface,
                              fixedSize: const Size.square(38),
                              padding: EdgeInsets.zero,
                              side: BorderSide(color: controlBorder),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildSharedItemsSection(
                        myUid: myUid,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        inputBg: controlSurface,
                        borderColor: controlBorder,
                        feedbackContext: parentContext,
                      ),
                      const SizedBox(height: 20),
                      Text("Hızlı durum", style: sectionLabelStyle),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          children: [
                            _statusButton(
                              sheetContext,
                              parentContext,
                              myUid,
                              "calm",
                              "Sakinim",
                              controlSurface,
                              textColor,
                              controlBorder,
                            ),
                            _statusButton(
                              sheetContext,
                              parentContext,
                              myUid,
                              "chat",
                              "Konuşalım",
                              controlSurface,
                              textColor,
                              controlBorder,
                            ),
                            _statusButton(
                              sheetContext,
                              parentContext,
                              myUid,
                              "soon",
                              "Birazdan",
                              controlSurface,
                              textColor,
                              controlBorder,
                            ),
                            _statusButton(
                              sheetContext,
                              parentContext,
                              myUid,
                              "busy",
                              "Yoğunum",
                              controlSurface,
                              textColor,
                              controlBorder,
                            ),
                            _statusButton(
                              sheetContext,
                              parentContext,
                              myUid,
                              "coffee",
                              "Kahve",
                              controlSurface,
                              textColor,
                              controlBorder,
                            ),
                            _statusButton(
                              sheetContext,
                              parentContext,
                              myUid,
                              "thinking",
                              "Seni düşünüyorum",
                              controlSurface,
                              textColor,
                              controlBorder,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text("Özel durum", style: sectionLabelStyle),
                      const SizedBox(height: 9),
                      TextField(
                        controller: customStatusController,
                        maxLength: 28,
                        textInputAction: TextInputAction.send,
                        cursorColor: textColor,
                        onSubmitted: (_) => submitCustomStatus(sheetContext),
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        decoration: InputDecoration(
                          hintText: "Şu an nasıl hissediyorsun?",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: mutedColor,
                            letterSpacing: 0,
                          ),
                          counterText: "",
                          filled: true,
                          fillColor: inputSurface,
                          isDense: true,
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            15,
                            7,
                            15,
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 50,
                            minHeight: 50,
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: customStatusController,
                            builder: (context, value, child) {
                              final enabled = value.text.trim().isNotEmpty;
                              return Padding(
                                padding: const EdgeInsets.all(7),
                                child: buildComposerAction(
                                  enabled: enabled,
                                  tooltip: "Durumu gönder",
                                  onPressed: () =>
                                      submitCustomStatus(sheetContext),
                                ),
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: controlBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: controlBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: focusedBorder,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text("Mini not", style: sectionLabelStyle),
                          const Spacer(),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: noteController,
                            builder: (context, value, child) {
                              return Text(
                                "${value.text.length}/80",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                  letterSpacing: 0,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Stack(
                        children: [
                          TextField(
                            controller: noteController,
                            maxLength: 80,
                            minLines: 3,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                            cursorColor: textColor,
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  "Partnerinin kartında görünecek kısa bir not yaz.",
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: mutedColor,
                                letterSpacing: 0,
                                height: 1.35,
                              ),
                              counterText: "",
                              filled: true,
                              fillColor: inputSurface,
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                58,
                                14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(color: controlBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(color: controlBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: focusedBorder,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: noteController,
                              builder: (context, value, child) {
                                final enabled = value.text.trim().isNotEmpty;
                                return buildComposerAction(
                                  enabled: enabled,
                                  tooltip: "Notu gönder",
                                  onPressed: () => submitNote(sheetContext),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.16 : 0.055,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: controlSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: controlBorder),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(sheetContext).pop(true);
                            },
                            splashColor: textColor.withValues(alpha: 0.06),
                            highlightColor: textColor.withValues(alpha: 0.035),
                            child: SizedBox(
                              height: 52,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: textColor.withValues(
                                          alpha: 0.07,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.draw_outlined,
                                        size: 17,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Text(
                                        "Çizim gönder",
                                        style: GoogleFonts.inter(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: mutedColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Navigator pop gelecegi kapanis animasyonundan once tamamlanabilir.
    // Eski sheet sokulmeden controller temizleme veya yeni sheet acma.
    while (activeSheetContext?.mounted ?? false) {
      await WidgetsBinding.instance.endOfFrame;
    }

    customStatusController.dispose();
    noteController.dispose();

    if (openSketch == true && parentContext.mounted) {
      _showSketchComposer(parentContext, myUid);
    }
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
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: mutedColor,
                letterSpacing: 0,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            if (!hasNote && !hasSketch)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: mutedColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 16,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Henüz paylaştığın bir not veya çizim yok.",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: mutedColor,
                          letterSpacing: 0,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (hasNote)
              _buildSharedItemCard(
                title: "Mini not",
                icon: Icons.mail_outline_rounded,
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
                  } catch (error, stackTrace) {
                    if (!feedbackContext.mounted) return;
                    await _showPartnerFailure(
                      feedbackContext,
                      error,
                      stackTrace,
                      operation: 'partner.delete_note',
                      fallbackMessage: 'Mini not silinemedi.',
                    );
                  }
                },
                child: Text(
                  noteText,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                    letterSpacing: 0,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (hasNote && hasSketch) const SizedBox(height: 8),
            if (hasSketch)
              _buildSharedSketchCard(
                context: context,
                strokes: sketchStrokes,
                textColor: textColor,
                mutedColor: mutedColor,
                inputBg: inputBg,
                borderColor: borderColor,
                onOpen: () => _showSketchPreview(context, sketchStrokes),
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
                  } catch (error, stackTrace) {
                    if (!feedbackContext.mounted) return;
                    await _showPartnerFailure(
                      feedbackContext,
                      error,
                      stackTrace,
                      operation: 'partner.delete_sketch',
                      fallbackMessage: 'Çizim silinemedi.',
                    );
                  }
                },
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

  Widget _buildSharedSketchCard({
    required BuildContext context,
    required List<_SketchStroke> strokes,
    required Color textColor,
    required Color mutedColor,
    required Color inputBg,
    required Color borderColor,
    required VoidCallback onOpen,
    required Future<void> Function() onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark
        ? const Color(0xFFF5F5F7).withValues(alpha: 0.94)
        : const Color(0xFFF2F2F7).withValues(alpha: 0.88);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.065),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.draw_outlined, size: 16, color: textColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Çizim",
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0,
                    height: 1.1,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Çizimi sil",
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                style: IconButton.styleFrom(
                  foregroundColor: mutedColor,
                  backgroundColor: mutedColor.withValues(alpha: 0.08),
                  fixedSize: const Size.square(34),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Semantics(
            button: true,
            label: "Çizimi büyüt",
            child: Material(
              color: paperColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.055)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onOpen,
                splashColor: textColor.withValues(alpha: 0.05),
                highlightColor: textColor.withValues(alpha: 0.025),
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CustomPaint(
                        painter: _SketchPainter(strokes),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(11, 10, 8, 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.065),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: textColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: "$title sil",
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            style: IconButton.styleFrom(
              foregroundColor: mutedColor,
              backgroundColor: mutedColor.withValues(alpha: 0.08),
              fixedSize: const Size.square(34),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // --- HAZIR DURUM BUTONU ---
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Semantics(
        button: true,
        label: "Durumu $text olarak güncelle",
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final nav = Navigator.of(context);
                try {
                  await _updateStatus(myUid, icon, text);
                  _notifyPartner(icon, text);
                  if (context.mounted) nav.pop();
                  if (feedbackContext.mounted) {
                    AppFeedback.show(
                      feedbackContext,
                      "Durum güncellendi.",
                      type: AppFeedbackType.success,
                    );
                  }
                } catch (error, stackTrace) {
                  if (!feedbackContext.mounted) return;
                  await _showPartnerFailure(
                    feedbackContext,
                    error,
                    stackTrace,
                    operation: 'partner.update_quick_status',
                    fallbackMessage: 'Durum güncellenemedi.',
                  );
                }
              },
              splashColor: textColor.withValues(alpha: 0.06),
              highlightColor: textColor.withValues(alpha: 0.035),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 13, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.07),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: textColor.withValues(alpha: 0.045),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: _buildStatusMark(icon, textColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 124),
                        child: Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            height: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String myUid, String icon, String text) async {
    final now = DateTime.now();
    await _savePartnerShare(
      myUid,
      latestFields: {
        'statusIcon': icon,
        'statusText': text,
        'lastUpdated': FieldValue.serverTimestamp(),
        'statusExpiresAt': Timestamp.fromDate(
          PartnerStatusView.expiresAtFrom(now),
        ),
      },
      share: {
        'id': _newShareId(),
        'type': 'status',
        'icon': icon,
        'text': text,
        'createdAt': now.toIso8601String(),
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

    _notifyPartner("note", note);
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
    final highContrast = MediaQuery.of(context).highContrast;
    final glassTint = isDark
        ? const Color(0xFF141416).withValues(alpha: highContrast ? 0.96 : 0.82)
        : Colors.white.withValues(alpha: highContrast ? 0.97 : 0.78);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.88);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.26),
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                blurRadius: 34,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: glassTint,
                  border: Border.all(color: glassBorder),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    mediaQuery.viewInsets.bottom + 20,
                  ),
                  child: _SketchComposer(
                    onClose: () => Navigator.of(sheetContext).pop(),
                    onSend: (strokes) async {
                      final nav = Navigator.of(sheetContext);
                      try {
                        await _sendPartnerSketch(myUid, strokes);
                        if (sheetContext.mounted) nav.pop();
                        if (feedbackContext.mounted) {
                          AppFeedback.show(
                            feedbackContext,
                            "Çizim gönderildi.",
                            type: AppFeedbackType.success,
                          );
                        }
                      } catch (error, stackTrace) {
                        if (!feedbackContext.mounted) return;
                        await _showPartnerFailure(
                          feedbackContext,
                          error,
                          stackTrace,
                          operation: 'partner.send_sketch',
                          fallbackMessage: 'Çizim gönderilemedi.',
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

    _notifyPartner("sketch", "Sana bir çizim gönderdi.");
  }

  Future<void> _deletePartnerSketch(String myUid) async {
    await _deletePartnerShareType(myUid, 'sketch', {
      'partnerSketch': FieldValue.delete(),
    });
  }

  // Partner bildirimi yalnızca kimliği doğrulanmış callable Function üzerinden gider.
  Future<void> _notifyPartner(String kind, String text) async {
    try {
      final normalizedKind = kind == 'note' || kind == 'sketch'
          ? kind
          : 'status';
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('notifyPartner')
          .call(<String, dynamic>{'kind': normalizedKind, 'text': text});
    } catch (error, stackTrace) {
      // Bildirim hatası partner paylaşımının kaydedilmesini engellemez.
      await AppErrorHandler.capture(
        error,
        stackTrace,
        operation: 'partner.notify',
        fallbackMessage: 'Partner bildirimi gönderilemedi.',
      );
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
  const _SketchComposer({required this.onClose, required this.onSend});

  final VoidCallback onClose;
  final Future<void> Function(List<_SketchStroke> strokes) onSend;

  @override
  State<_SketchComposer> createState() => _SketchComposerState();
}

class _SketchComposerState extends State<_SketchComposer> {
  static const int _maxStrokes = 80;
  static const int _maxPoints = 2500;
  static const double _minPointDistanceSquared = 0.000016;

  final List<_SketchStroke> _strokes = [];
  Color _selectedColor = const Color(0xFF0A2342);
  bool _isSending = false;
  int _pointCount = 0;

  void _startStroke(Offset localPosition, Size size) {
    if (_strokes.length >= _maxStrokes || _pointCount >= _maxPoints) return;
    final point = _normalize(localPosition, size);
    setState(() {
      _strokes.add(
        _SketchStroke(
          colorValue: _selectedColor.toARGB32(),
          width: 4,
          points: [point],
        ),
      );
      _pointCount += 1;
    });
  }

  void _extendStroke(Offset localPosition, Size size) {
    if (_strokes.isEmpty || _pointCount >= _maxPoints) return;
    final point = _normalize(localPosition, size);
    final previous = _strokes.last.points.last;
    if ((point - previous).distanceSquared < _minPointDistanceSquared) return;

    setState(() {
      _strokes.last.points.add(point);
      _pointCount += 1;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _pointCount -= _strokes.last.points.length;
      _strokes.removeLast();
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _pointCount = 0;
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
    final highContrast = MediaQuery.of(context).highContrast;
    final textColor = isDark
        ? const Color(0xFFF5F5F7)
        : const Color(0xFF111114);
    final mutedColor = isDark
        ? const Color(0xFFA1A1A6)
        : const Color(0xFF6E6E73);
    final controlSurface = isDark
        ? Colors.white.withValues(alpha: highContrast ? 0.14 : 0.08)
        : Colors.white.withValues(alpha: highContrast ? 0.92 : 0.58);
    final canvasSurface = isDark
        ? const Color(0xFF222225).withValues(alpha: highContrast ? 0.98 : 0.92)
        : const Color(0xFFF8F8FA).withValues(alpha: highContrast ? 1 : 0.94);
    final controlBorder = isDark
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.black.withValues(alpha: 0.065);
    final actionBackground = isDark
        ? const Color(0xFFF5F5F7)
        : const Color(0xFF111114);
    final actionForeground = isDark ? const Color(0xFF111114) : Colors.white;
    final canSend = _strokes.isNotEmpty && !_isSending;
    final sectionLabelStyle = GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: mutedColor,
      letterSpacing: 0,
      height: 1.1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Çizim gönder",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Partnerinin kartında görünecek bir çizim bırak.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: mutedColor,
                      letterSpacing: 0,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: "Kapat",
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, size: 19),
              style: IconButton.styleFrom(
                foregroundColor: textColor,
                backgroundColor: controlSurface,
                fixedSize: const Size.square(38),
                padding: EdgeInsets.zero,
                side: BorderSide(color: controlBorder),
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text("Çizim alanı", style: sectionLabelStyle),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: controlBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.075),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _isSending
                      ? null
                      : (details) =>
                            _startStroke(details.localPosition, canvasSize),
                  onPanUpdate: _isSending
                      ? null
                      : (details) =>
                            _extendStroke(details.localPosition, canvasSize),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: canvasSurface,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _SketchPainter(_strokes),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: controlSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: controlBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.055),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _colorButton(
                const Color(0xFF0A2342),
                "Gece laciverti",
                textColor,
              ),
              _colorButton(const Color(0xFF1F91DC), "Mavi", textColor),
              _colorButton(const Color(0xFFE57373), "Kırmızı", textColor),
              _colorButton(const Color(0xFF2E7D32), "Yeşil", textColor),
              const Spacer(),
              _toolButton(
                icon: Icons.undo_rounded,
                tooltip: "Geri al",
                onPressed: _strokes.isEmpty || _isSending ? null : _undo,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(width: 4),
              _toolButton(
                icon: Icons.delete_outline_rounded,
                tooltip: "Temizle",
                onPressed: _strokes.isEmpty || _isSending ? null : _clear,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: canSend
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.24 : 0.14,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : const [],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: canSend ? _send : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: _isSending
                    ? SizedBox(
                        key: const ValueKey("sending"),
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: actionForeground,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        key: ValueKey("send"),
                        size: 18,
                      ),
              ),
              label: Text(
                _isSending ? "Gönderiliyor..." : "Çizimi gönder",
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: actionBackground,
                foregroundColor: actionForeground,
                disabledBackgroundColor: _isSending
                    ? actionBackground.withValues(alpha: 0.82)
                    : controlSurface,
                disabledForegroundColor: _isSending
                    ? actionForeground
                    : mutedColor.withValues(alpha: 0.58),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                side: BorderSide(
                  color: canSend || _isSending
                      ? Colors.transparent
                      : controlBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorButton(Color color, String label, Color selectionColor) {
    final selected = _selectedColor == color;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: "$label çizim rengi",
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isSending
                ? null
                : () => setState(() => _selectedColor = color),
            child: SizedBox(
              width: 40,
              height: 48,
              child: Center(
                child: AnimatedScale(
                  scale: selected ? 1 : 0.92,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    padding: EdgeInsets.all(selected ? 4 : 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? selectionColor.withValues(alpha: 0.07)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? selectionColor.withValues(alpha: 0.52)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color textColor,
    required Color mutedColor,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      style: IconButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: textColor.withValues(alpha: 0.065),
        disabledForegroundColor: mutedColor.withValues(alpha: 0.38),
        disabledBackgroundColor: mutedColor.withValues(alpha: 0.035),
        fixedSize: const Size.square(38),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
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
  const _SketchPainter(
    this.strokes, {
    this.fitToContent = false,
    this.previewPadding = 0,
  });

  final List<_SketchStroke> strokes;
  final bool fitToContent;
  final double previewPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final mapPoint = fitToContent
        ? _contentFittedMapper(size)
        : (Offset point) =>
              Offset(point.dx * size.width, point.dy * size.height);

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
      final firstPoint = mapPoint(first);
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          firstPoint,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }

      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (final point in stroke.points.skip(1)) {
        final mappedPoint = mapPoint(point);
        path.lineTo(mappedPoint.dx, mappedPoint.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  Offset Function(Offset) _contentFittedMapper(Size size) {
    var hasPoint = false;
    var minX = 0.0;
    var maxX = 0.0;
    var minY = 0.0;
    var maxY = 0.0;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        if (!hasPoint) {
          minX = maxX = point.dx;
          minY = maxY = point.dy;
          hasPoint = true;
          continue;
        }
        if (point.dx < minX) minX = point.dx;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    Offset defaultMapper(Offset point) =>
        Offset(point.dx * size.width, point.dy * size.height);
    if (!hasPoint) return defaultMapper;

    // Compact previews trim empty canvas space, then scale uniformly so the
    // normalized square drawing remains undistorted in a horizontal frame.
    const minimumSpan = 0.12;
    var sourceWidth = maxX - minX;
    var sourceHeight = maxY - minY;
    if (sourceWidth < minimumSpan) {
      final centerX = (minX + maxX) / 2;
      minX = centerX - minimumSpan / 2;
      maxX = centerX + minimumSpan / 2;
      sourceWidth = minimumSpan;
    }
    if (sourceHeight < minimumSpan) {
      final centerY = (minY + maxY) / 2;
      minY = centerY - minimumSpan / 2;
      maxY = centerY + minimumSpan / 2;
      sourceHeight = minimumSpan;
    }

    final dominantSpan = sourceWidth > sourceHeight
        ? sourceWidth
        : sourceHeight;
    final sourceMargin = dominantSpan * 0.09;
    minX -= sourceMargin;
    maxX += sourceMargin;
    minY -= sourceMargin;
    maxY += sourceMargin;
    sourceWidth = maxX - minX;
    sourceHeight = maxY - minY;

    final availableWidth = size.width - previewPadding * 2;
    final availableHeight = size.height - previewPadding * 2;
    if (availableWidth <= 0 || availableHeight <= 0) return defaultMapper;

    final scaleX = availableWidth / sourceWidth;
    final scaleY = availableHeight / sourceHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final fittedWidth = sourceWidth * scale;
    final fittedHeight = sourceHeight * scale;
    final originX = (size.width - fittedWidth) / 2;
    final originY = (size.height - fittedHeight) / 2;

    return (point) => Offset(
      originX + (point.dx - minX) * scale,
      originY + (point.dy - minY) * scale,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) {
    return true;
  }
}
