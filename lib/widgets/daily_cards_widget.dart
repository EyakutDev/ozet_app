import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/models/daily_score_entry.dart';

class DailyCardsWidget extends StatefulWidget {
  const DailyCardsWidget({
    super.key,
    required this.entry,
    required this.isLoading,
    required this.onDailyScoreTap,
    required this.onHistoryTap,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
  });

  final DailyScoreEntry? entry;
  final bool isLoading;
  final VoidCallback onDailyScoreTap;
  final VoidCallback onHistoryTap;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;

  @override
  State<DailyCardsWidget> createState() => _DailyCardsWidgetState();
}

class _DailyCardsWidgetState extends State<DailyCardsWidget> {
  int _currentPage = 0;

  bool _isVisibleNews(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final published = data['published'];
    final status = (data['status'] as String?)?.trim().toLowerCase();

    if (published == false) return false;
    if (status == 'draft' || status == 'rejected') return false;
    return published == true || status == 'published' || status == null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreAccent = isDark
        ? const Color(0xFFF5F5F5)
        : const Color(0xFF111111);
    final activeAccent = _currentPage == 0 ? scoreAccent : Colors.teal;
    final borderColor = isDark ? Colors.grey[850]! : const Color(0xFFE9EEF4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : activeAccent.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: PageView(
          scrollDirection: Axis.horizontal,
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: [_buildDailyScorePage(scoreAccent), _buildDetoxPage()],
        ),
      ),
    );
  }

  Widget _buildDailyScorePage(Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onDailyScoreTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                title: 'Günün Puanı',
                icon: Icons.history_rounded,
                accentColor: accentColor,
                onAction: widget.onHistoryTap,
                actionTooltip: 'Geçmiş günler',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: widget.isLoading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        ),
                      )
                    : widget.entry == null
                    ? _buildEmptyDailyScore(accentColor)
                    : _buildCompletedDailyScore(widget.entry!, accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDailyScore(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bugününü\ndeğerlendir',
          style: GoogleFonts.kadwa(
            color: widget.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
        Row(
          children: [
            Text(
              'Başla',
              style: GoogleFonts.kadwa(
                color: widget.mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 11, color: widget.mutedColor),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedDailyScore(DailyScoreEntry entry, Color accentColor) {
    final scoreText = entry.average.toStringAsFixed(1).replaceAll('.', ',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              scoreText,
              style: GoogleFonts.kadwa(
                color: accentColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 0.9,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 1),
              child: Text(
                '/10',
                style: GoogleFonts.kadwa(
                  color: widget.mutedColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        Text(
          entry.summaryLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.kadwa(
            color: widget.textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                entry.note.isEmpty ? 'Düzenle' : entry.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.kadwa(color: widget.mutedColor, fontSize: 9),
              ),
            ),
            Icon(Icons.edit_outlined, size: 13, color: widget.mutedColor),
          ],
        ),
      ],
    );
  }

  Widget _buildDetoxPage() {
    const accentColor = Colors.teal;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        final newsCount = snapshot.hasData
            ? snapshot.data!.docs.where(_isVisibleNews).length
            : null;
        final savedMinutes = newsCount == null ? null : newsCount * 4;

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeader(
                title: 'Detoks',
                icon: Icons.spa_outlined,
                accentColor: accentColor,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savedMinutes == null ? '--' : '$savedMinutes dk',
                    style: GoogleFonts.kadwa(
                      color: accentColor,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'kazandığın süre',
                    style: GoogleFonts.kadwa(
                      color: widget.mutedColor,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              Text(
                newsCount == null ? 'Yükleniyor' : '$newsCount özet okundu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.kadwa(
                  color: widget.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required String title,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onAction,
    String? actionTooltip,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.kadwa(color: widget.mutedColor, fontSize: 14),
          ),
        ),
        _buildPageDots(accentColor),
        const SizedBox(width: 7),
        if (onAction == null)
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          )
        else
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              onPressed: onAction,
              tooltip: actionTooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              style: IconButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.12),
                foregroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(icon, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildPageDots(Color activeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(left: 3),
          width: isActive ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : widget.mutedColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
