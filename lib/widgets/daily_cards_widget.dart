import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/widgets/home_panel_controls.dart';

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
    this.embedded = false,
  });

  final DailyScoreEntry? entry;
  final bool isLoading;
  final VoidCallback onDailyScoreTap;
  final VoidCallback onHistoryTap;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final bool embedded;

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
    final borderColor = isDark ? Colors.grey[850]! : const Color(0xFFE9EEF4);
    final pages = PageView(
      scrollDirection: Axis.horizontal,
      onPageChanged: (index) => setState(() => _currentPage = index),
      children: [
        _buildDailyScorePage(scoreAccent),
        _buildDetoxPage(scoreAccent),
      ],
    );

    if (widget.embedded) return pages;

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
                : scoreAccent.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: pages),
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
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bugününü değerlendir',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        HomePanelFooter(
          activeIndex: _currentPage,
          foregroundColor: accentColor,
          mutedColor: widget.mutedColor,
          actionLabel: 'Değerlendir',
        ),
      ],
    );
  }

  Widget _buildCompletedDailyScore(DailyScoreEntry entry, Color accentColor) {
    final scoreText = entry.average.toStringAsFixed(1).replaceAll('.', ',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    scoreText,
                    style: GoogleFonts.inter(
                      color: accentColor,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 2),
                    child: Text(
                      '/10',
                      style: GoogleFonts.inter(
                        color: widget.mutedColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                entry.summaryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: widget.textColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        HomePanelFooter(
          activeIndex: _currentPage,
          foregroundColor: accentColor,
          mutedColor: widget.mutedColor,
          actionLabel: 'Düzenle',
        ),
      ],
    );
  }

  Widget _buildDetoxPage(Color accentColor) {
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
            children: [
              _buildHeader(
                title: 'Detoks',
                icon: Icons.spa_outlined,
                accentColor: accentColor,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      savedMinutes == null ? '--' : '$savedMinutes dk',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: accentColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      newsCount == null ? 'Hesaplanıyor' : '$newsCount özet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: widget.mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              HomePanelFooter(
                activeIndex: _currentPage,
                foregroundColor: accentColor,
                mutedColor: widget.mutedColor,
                showChevron: false,
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
            style: GoogleFonts.inter(
              color: widget.mutedColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
        HomePanelIcon(
          icon: icon,
          foregroundColor: accentColor,
          onTap: onAction,
          tooltip: actionTooltip,
        ),
      ],
    );
  }
}
