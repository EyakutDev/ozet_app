import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/models/daily_score_statistics.dart';
import 'package:ozet_app/screens/daily_score_history_screen.dart';
import 'package:ozet_app/services/daily_score_storage.dart';
import 'package:ozet_app/widgets/daily_score_calendar_view.dart';
import 'package:ozet_app/widgets/liquid_glass_app_bar.dart';

class DailyScoreStatisticsScreen extends StatefulWidget {
  DailyScoreStatisticsScreen({super.key, DailyScoreStorage? storage})
    : storage = storage ?? DailyScoreStorage();

  final DailyScoreStorage storage;

  @override
  State<DailyScoreStatisticsScreen> createState() =>
      _DailyScoreStatisticsScreenState();
}

class _DailyScoreStatisticsScreenState
    extends State<DailyScoreStatisticsScreen> {
  final ScrollController _scrollController = ScrollController();
  late Future<List<DailyScoreEntry>> _entriesFuture;
  late DateTime _visibleMonth;
  DailyScoreStatisticsView _selectedView = DailyScoreStatisticsView.week;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _entriesFuture = widget.storage.getAll();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final nextValue = _scrollController.offset > 10;
    if (nextValue == _isScrolled) return;
    setState(() => _isScrolled = nextValue);
  }

  Future<void> _reload() async {
    final future = widget.storage.getAll();
    setState(() => _entriesFuture = future);
    await future;
  }

  void _selectView(DailyScoreStatisticsView view) {
    if (view == _selectedView) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedView = view);
  }

  void _moveMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (nextMonth.isAfter(currentMonth)) return;

    HapticFeedback.selectionClick();
    setState(() => _visibleMonth = nextMonth);
  }

  void _openEntry(DailyScoreEntry entry) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DailyScoreDetailScreen(entry: entry)),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _StatisticsPalette.of(context);
    final overlayStyle = palette.isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: _reload,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            LiquidGlassSliverAppBar(
              isDark: palette.isDark,
              isScrolled: _isScrolled,
              systemOverlayStyle: overlayStyle,
              leading: LiquidGlassIconButton(
                isDark: palette.isDark,
                foregroundColor: palette.text,
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 17,
                tooltip: 'Geri',
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'İstatistikler',
                style: GoogleFonts.inter(
                  color: palette.text,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<DailyScoreEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return SizedBox(
                      height: MediaQuery.sizeOf(context).height - 150,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.accent,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _StatisticsMessage(
                      palette: palette,
                      icon: Icons.error_outline_rounded,
                      title: 'İstatistikler açılamadı',
                      detail: 'Kayıtlar okunurken bir sorun oluştu.',
                      action: TextButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Tekrar dene'),
                      ),
                    );
                  }

                  final entries = snapshot.data ?? const <DailyScoreEntry>[];
                  final statistics = DailyScoreStatistics.fromEntries(entries);
                  final calendar = DailyScoreCalendarMonth.fromEntries(
                    entries,
                    _visibleMonth,
                  );
                  return _StatisticsContent(
                    statistics: statistics,
                    calendar: calendar,
                    palette: palette,
                    selectedView: _selectedView,
                    onViewChanged: _selectView,
                    onPreviousMonth: () => _moveMonth(-1),
                    onNextMonth: () => _moveMonth(1),
                    onEntryTap: _openEntry,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({
    required this.statistics,
    required this.calendar,
    required this.palette,
    required this.selectedView,
    required this.onViewChanged,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onEntryTap,
  });

  final DailyScoreStatistics statistics;
  final DailyScoreCalendarMonth calendar;
  final _StatisticsPalette palette;
  final DailyScoreStatisticsView selectedView;
  final ValueChanged<DailyScoreStatisticsView> onViewChanged;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DailyScoreEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canMoveNext = calendar.month.isBefore(DateTime(now.year, now.month));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.paddingOf(context).bottom + 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DailyScoreStatisticsViewControl(
                selectedView: selectedView,
                onChanged: onViewChanged,
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                reverseDuration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final scale = Tween<double>(begin: 0.985, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  );
                },
                child: selectedView == DailyScoreStatisticsView.week
                    ? Column(
                        key: const ValueKey('weekly-statistics'),
                        children: [
                          _OverviewCard(
                            statistics: statistics,
                            palette: palette,
                          ),
                          const SizedBox(height: 14),
                          _WeeklyChartCard(
                            statistics: statistics,
                            palette: palette,
                          ),
                          const SizedBox(height: 14),
                          _QuestionAveragesCard(
                            statistics: statistics,
                            palette: palette,
                          ),
                        ],
                      )
                    : DailyScoreCalendarView(
                        key: ValueKey(calendar.month),
                        calendar: calendar,
                        canMoveNext: canMoveNext,
                        onPreviousMonth: onPreviousMonth,
                        onNextMonth: onNextMonth,
                        onEntryTap: onEntryTap,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.statistics, required this.palette});

  final DailyScoreStatistics statistics;
  final _StatisticsPalette palette;

  @override
  Widget build(BuildContext context) {
    final averageText = _formatScore(statistics.weeklyAverage);

    return _StatisticsGlassSurface(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: palette.glassStrong,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  'Son 7 gün',
                  style: GoogleFonts.inter(
                    color: palette.text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _dateRange(statistics.points),
                style: GoogleFonts.inter(
                  color: palette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            'Haftalık görünüm',
            style: GoogleFonts.inter(
              color: palette.text,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'Ortalama',
                  value: averageText,
                  suffix: statistics.weeklyAverage == null ? null : '/10',
                  palette: palette,
                ),
              ),
              Container(width: 1, height: 54, color: palette.border),
              Expanded(
                child: _OverviewMetric(
                  label: 'Tamamlanan',
                  value: '${statistics.completedDays}',
                  suffix: '/7 gün',
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 15),
          _ComparisonLine(statistics: statistics, palette: palette),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.suffix,
    required this.palette,
  });

  final String label;
  final String value;
  final String? suffix;
  final _StatisticsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: palette.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: palette.accent,
                fontSize: 31,
                fontWeight: FontWeight.w700,
                height: 0.95,
                letterSpacing: 0,
              ),
            ),
            if (suffix != null)
              Padding(
                padding: const EdgeInsets.only(left: 3, bottom: 2),
                child: Text(
                  suffix!,
                  style: GoogleFonts.inter(
                    color: palette.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine({required this.statistics, required this.palette});

  final DailyScoreStatistics statistics;
  final _StatisticsPalette palette;

  @override
  Widget build(BuildContext context) {
    final difference = statistics.weeklyDifference;
    final hasComparison = difference != null;
    final isFlat = hasComparison && difference.abs() < 0.05;
    final isUp = hasComparison && !isFlat && difference > 0;
    final icon = !hasComparison
        ? Icons.horizontal_rule_rounded
        : isFlat
        ? Icons.trending_flat_rounded
        : isUp
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final text = !hasComparison
        ? 'Önceki haftayla karşılaştırmak için daha fazla kayıt gerekli.'
        : isFlat
        ? 'Geçen haftayla aynı seviyede.'
        : 'Geçen haftaya göre ${_formatScore(difference.abs())} puan '
              '${isUp ? 'yükseldi' : 'düştü'}.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.controlSurface,
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, size: 17, color: palette.text),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: hasComparison ? palette.text : palette.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.statistics, required this.palette});

  final DailyScoreStatistics statistics;
  final _StatisticsPalette palette;

  @override
  Widget build(BuildContext context) {
    return _StatisticsGlassSurface(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Puan akışı',
            style: GoogleFonts.inter(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Günlük ortalamanın son yedi gündeki hareketi',
            style: GoogleFonts.inter(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          _WeeklyLineChart(points: statistics.points, palette: palette),
        ],
      ),
    );
  }
}

class _WeeklyLineChart extends StatelessWidget {
  const _WeeklyLineChart({required this.points, required this.palette});

  final List<DailyScoreDayPoint> points;
  final _StatisticsPalette palette;

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((point) => point.average != null);

    return Semantics(
      label: 'Son yedi gün puan grafiği',
      child: SizedBox(
        height: 184,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _axisText('10', palette),
                        _axisText('5', palette),
                        _axisText('1', palette),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _WeeklyChartPainter(
                              points: points,
                              palette: palette,
                            ),
                          ),
                        ),
                        if (!hasData)
                          Text(
                            'Henüz grafik oluşturacak kayıt yok.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: palette.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  for (final point in points)
                    Expanded(
                      child: Text(
                        _shortWeekday(point.date),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  const _WeeklyChartPainter({required this.points, required this.palette});

  final List<DailyScoreDayPoint> points;
  final _StatisticsPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || points.isEmpty) return;

    final plot = Rect.fromLTWH(6, 5, size.width - 12, size.height - 10);
    final gridPaint = Paint()
      ..color = palette.track
      ..strokeWidth = 1;

    double yFor(double score) {
      final normalized = ((score - 1) / 9).clamp(0.0, 1.0);
      return plot.bottom - (plot.height * normalized);
    }

    for (final score in const [10.0, 5.0, 1.0]) {
      final y = yFor(score);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    final coordinates = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final value = points[index].average;
      if (value == null) continue;
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + (plot.width * index / (points.length - 1));
      coordinates.add(Offset(x, yFor(value)));
    }
    if (coordinates.isEmpty) return;

    if (coordinates.length > 1) {
      final path = Path()..moveTo(coordinates.first.dx, coordinates.first.dy);
      for (final point in coordinates.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      final fillPath = Path.from(path)
        ..lineTo(coordinates.last.dx, plot.bottom)
        ..lineTo(coordinates.first.dx, plot.bottom)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.accent.withValues(alpha: 0.13),
            palette.accent.withValues(alpha: 0),
          ],
        ).createShader(plot);
      canvas.drawPath(fillPath, fillPaint);

      canvas.drawPath(
        path,
        Paint()
          ..color = palette.accent
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    for (final point in coordinates) {
      canvas
        ..drawCircle(point, 5.2, Paint()..color = palette.glassStrong)
        ..drawCircle(point, 3.1, Paint()..color = palette.accent);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.palette.accent != palette.accent ||
        oldDelegate.palette.track != palette.track;
  }
}

class _QuestionAveragesCard extends StatelessWidget {
  const _QuestionAveragesCard({
    required this.statistics,
    required this.palette,
  });

  final DailyScoreStatistics statistics;
  final _StatisticsPalette palette;

  @override
  Widget build(BuildContext context) {
    return _StatisticsGlassSurface(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Haftalık başlıklar',
            style: GoogleFonts.inter(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Her değerlendirme başlığının yedi günlük ortalaması',
            style: GoogleFonts.inter(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 13),
          for (var index = 0; index < dailyScoreQuestions.length; index++) ...[
            _QuestionAverageRow(
              question: dailyScoreQuestions[index],
              average:
                  statistics.questionAverages[dailyScoreQuestions[index].id],
              palette: palette,
            ),
            if (index < dailyScoreQuestions.length - 1)
              Divider(height: 1, color: palette.border),
          ],
        ],
      ),
    );
  }
}

class _QuestionAverageRow extends StatelessWidget {
  const _QuestionAverageRow({
    required this.question,
    required this.average,
    required this.palette,
  });

  final DailyScoreQuestion question;
  final double? average;
  final _StatisticsPalette palette;

  @override
  Widget build(BuildContext context) {
    final progress = ((average ?? 0) / 10).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              question.shortTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.text,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(end: progress),
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    color: palette.accent,
                    backgroundColor: palette.track,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 42,
            child: Text(
              average == null ? '–' : _formatScore(average),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: average == null ? palette.muted : palette.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsMessage extends StatelessWidget {
  const _StatisticsMessage({
    required this.palette,
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final _StatisticsPalette palette;
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 40, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _StatisticsGlassSurface(
            palette: palette,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(icon, size: 30, color: palette.text),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: palette.muted,
                    fontSize: 12,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 10), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsGlassSurface extends StatelessWidget {
  const _StatisticsGlassSurface({
    required this.palette,
    required this.padding,
    required this.child,
  });

  final _StatisticsPalette palette;
  final EdgeInsetsGeometry padding;
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
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _StatisticsPalette {
  const _StatisticsPalette({
    required this.isDark,
    required this.scaffold,
    required this.text,
    required this.muted,
    required this.glass,
    required this.glassStrong,
    required this.controlSurface,
    required this.border,
    required this.track,
    required this.accent,
    required this.shadow,
  });

  final bool isDark;
  final Color scaffold;
  final Color text;
  final Color muted;
  final Color glass;
  final Color glassStrong;
  final Color controlSurface;
  final Color border;
  final Color track;
  final Color accent;
  final Color shadow;

  factory _StatisticsPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _StatisticsPalette(
      isDark: isDark,
      scaffold: isDark ? const Color(0xFF0D0D0E) : const Color(0xFFF2F2F4),
      text: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF111114),
      muted: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
      glass: isDark
          ? const Color(0xFF1C1C1E).withValues(alpha: 0.80)
          : Colors.white.withValues(alpha: 0.74),
      glassStrong: isDark
          ? const Color(0xFF2C2C2E).withValues(alpha: 0.78)
          : Colors.white.withValues(alpha: 0.86),
      controlSurface: isDark
          ? Colors.white.withValues(alpha: 0.065)
          : Colors.white.withValues(alpha: 0.62),
      border: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
      track: isDark
          ? Colors.white.withValues(alpha: 0.13)
          : Colors.black.withValues(alpha: 0.09),
      accent: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF111114),
      shadow: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
    );
  }
}

Widget _axisText(String value, _StatisticsPalette palette) {
  return Text(
    value,
    style: GoogleFonts.inter(
      color: palette.muted,
      fontSize: 9,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
  );
}

String _formatScore(double? value) {
  if (value == null) return '–';
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _dateRange(List<DailyScoreDayPoint> points) {
  if (points.isEmpty) return '';
  final first = points.first.date;
  final last = points.last.date;
  if (first.month == last.month) {
    return '${first.day}–${last.day} ${_months[last.month - 1]}';
  }
  return '${first.day} ${_months[first.month - 1]} – '
      '${last.day} ${_months[last.month - 1]}';
}

String _shortWeekday(DateTime date) => _shortWeekdays[date.weekday - 1];

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
