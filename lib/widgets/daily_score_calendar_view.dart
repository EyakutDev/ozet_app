import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/models/daily_score_statistics.dart';

enum DailyScoreStatisticsView { week, calendar }

class DailyScoreStatisticsViewControl extends StatelessWidget {
  const DailyScoreStatisticsViewControl({
    super.key,
    required this.selectedView,
    required this.onChanged,
  });

  final DailyScoreStatisticsView selectedView;
  final ValueChanged<DailyScoreStatisticsView> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _CalendarPalette.of(context);

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.controlSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: selectedView == DailyScoreStatisticsView.week
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: constraints.maxWidth / 2,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ViewSegment(
                      label: 'Hafta',
                      selected: selectedView == DailyScoreStatisticsView.week,
                      palette: palette,
                      onTap: () => onChanged(DailyScoreStatisticsView.week),
                    ),
                  ),
                  Expanded(
                    child: _ViewSegment(
                      label: 'Takvim',
                      selected:
                          selectedView == DailyScoreStatisticsView.calendar,
                      palette: palette,
                      onTap: () => onChanged(DailyScoreStatisticsView.calendar),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class DailyScoreCalendarView extends StatelessWidget {
  const DailyScoreCalendarView({
    super.key,
    required this.calendar,
    required this.canMoveNext,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onEntryTap,
  });

  final DailyScoreCalendarMonth calendar;
  final bool canMoveNext;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DailyScoreEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    final palette = _CalendarPalette.of(context);

    return _CalendarGlassSurface(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük kayıtlar',
                      style: GoogleFonts.inter(
                        color: palette.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_months[calendar.month.month - 1]} '
                      '${calendar.month.year}',
                      style: GoogleFonts.inter(
                        color: palette.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              _MonthButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Önceki ay',
                palette: palette,
                onPressed: onPreviousMonth,
              ),
              const SizedBox(width: 8),
              _MonthButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Sonraki ay',
                palette: palette,
                onPressed: canMoveNext ? onNextMonth : null,
              ),
            ],
          ),
          const SizedBox(height: 21),
          Row(
            children: [
              for (final weekday in _shortWeekdays)
                Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: palette.muted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: DailyScoreCalendarMonth.totalCellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              final day = index - calendar.leadingEmptyDays + 1;
              if (day < 1 || day > calendar.daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                calendar.month.year,
                calendar.month.month,
                day,
              );
              final entry = calendar.entriesByDay[day];
              return _CalendarDayCell(
                date: date,
                entry: entry,
                palette: palette,
                onTap: entry == null ? null : () => onEntryTap(entry),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Puanı olan bir güne dokunarak gün kartını açabilirsin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: palette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSegment extends StatelessWidget {
  const _ViewSegment({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _CalendarPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: GoogleFonts.inter(
              color: selected ? palette.onAccent : palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final _CalendarPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: palette.text,
          disabledForegroundColor: palette.muted.withValues(alpha: 0.35),
          backgroundColor: palette.controlSurface,
          side: BorderSide(color: palette.border),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.entry,
    required this.palette,
    required this.onTap,
  });

  final DateTime date;
  final DailyScoreEntry? entry;
  final _CalendarPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = date.isAfter(today);
    final isToday = date == today;
    final normalizedScore = ((entry?.average ?? 0) / 10).clamp(0.0, 1.0);
    final hasEntry = entry != null && !isFuture;
    final usesLightText =
        !palette.isDark && hasEntry && normalizedScore >= 0.55;
    final foreground = isFuture
        ? palette.muted.withValues(alpha: 0.42)
        : hasEntry && usesLightText
        ? palette.onAccent
        : palette.text;
    final fillColor = palette.isDark
        ? hasEntry
              ? palette.accent.withValues(
                  alpha: 0.08 + (normalizedScore * 0.18),
                )
              : isFuture
              ? Colors.white.withValues(alpha: 0.035)
              : palette.controlSurface
        : hasEntry
        ? palette.accent.withValues(alpha: 0.11 + (normalizedScore * 0.45))
        : palette.controlSurface.withValues(alpha: isFuture ? 0.30 : 0.72);
    final cellBorder = isToday
        ? palette.accent
        : palette.isDark && hasEntry
        ? palette.accent.withValues(alpha: 0.14 + (normalizedScore * 0.16))
        : palette.border;

    return Semantics(
      button: hasEntry,
      label: hasEntry
          ? '${date.day} ${_months[date.month - 1]}, '
                '${_formatScore(entry!.average)} puan'
          : '${date.day} ${_months[date.month - 1]}, kayıt yok',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: hasEntry ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cellBorder, width: isToday ? 2 : 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: GoogleFonts.inter(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasEntry ? _formatScore(entry!.average) : '–',
                  style: GoogleFonts.inter(
                    color: hasEntry
                        ? foreground.withValues(alpha: 0.88)
                        : palette.muted.withValues(alpha: 0.58),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarGlassSurface extends StatelessWidget {
  const _CalendarGlassSurface({required this.palette, required this.child});

  final _CalendarPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.glass,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarPalette {
  const _CalendarPalette({
    required this.isDark,
    required this.text,
    required this.muted,
    required this.glass,
    required this.controlSurface,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.shadow,
  });

  final bool isDark;
  final Color text;
  final Color muted;
  final Color glass;
  final Color controlSurface;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color shadow;

  factory _CalendarPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CalendarPalette(
      isDark: isDark,
      text: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF111114),
      muted: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
      glass: isDark
          ? const Color(0xFF1C1C1E).withValues(alpha: 0.80)
          : Colors.white.withValues(alpha: 0.74),
      controlSurface: isDark
          ? Colors.white.withValues(alpha: 0.065)
          : Colors.white.withValues(alpha: 0.62),
      border: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
      accent: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF111114),
      onAccent: isDark ? const Color(0xFF111114) : Colors.white,
      shadow: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
    );
  }
}

String _formatScore(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const _shortWeekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
