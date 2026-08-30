import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/services/daily_score_storage.dart';

class DailyScoreHistoryScreen extends StatefulWidget {
  DailyScoreHistoryScreen({super.key, DailyScoreStorage? storage})
    : storage = storage ?? DailyScoreStorage();

  final DailyScoreStorage storage;

  @override
  State<DailyScoreHistoryScreen> createState() =>
      _DailyScoreHistoryScreenState();
}

class _DailyScoreHistoryScreenState extends State<DailyScoreHistoryScreen> {
  late Future<List<DailyScoreEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = widget.storage.getAll();
  }

  Future<void> _reload() async {
    final future = widget.storage.getAll();
    setState(() => _entriesFuture = future);
    await future;
  }

  void _openEntry(DailyScoreEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DailyScoreDetailScreen(entry: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HistoryPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Geçmiş Günler',
          style: GoogleFonts.kadwa(
            color: palette.text,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<DailyScoreEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                ),
              );
            }

            if (snapshot.hasError) {
              return _HistoryMessage(
                icon: Icons.error_outline_rounded,
                title: 'Kayıtlar açılamadı',
                palette: palette,
                action: TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Tekrar dene',
                    style: GoogleFonts.kadwa(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }

            final entries = snapshot.data ?? const <DailyScoreEntry>[];
            if (entries.isEmpty) {
              return _HistoryMessage(
                icon: Icons.calendar_month_outlined,
                title: 'Henüz geçmiş kayıt yok',
                palette: palette,
              );
            }

            final groups = _groupByMonth(entries);
            return RefreshIndicator(
              color: palette.accent,
              onRefresh: _reload,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _MonthSection(
                    group: group,
                    palette: palette,
                    onEntryTap: _openEntry,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class DailyScoreDetailScreen extends StatelessWidget {
  const DailyScoreDetailScreen({super.key, required this.entry});

  final DailyScoreEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = _HistoryPalette.of(context);
    final scoreText = entry.average.toStringAsFixed(1).replaceAll('.', ',');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gün Kartı',
          style: GoogleFonts.kadwa(
            color: palette.text,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultPanel(
                      entry: entry,
                      scoreText: scoreText,
                      palette: palette,
                    ),
                    const SizedBox(height: 22),
                    _SectionTitle(title: 'Puanların', palette: palette),
                    const SizedBox(height: 9),
                    _ScoreBreakdown(entry: entry, palette: palette),
                    const SizedBox(height: 22),
                    _SectionTitle(
                      title: 'Bugünden kalan not',
                      palette: palette,
                    ),
                    const SizedBox(height: 9),
                    _NotePanel(note: entry.note, palette: palette),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.group,
    required this.palette,
    required this.onEntryTap,
  });

  final _MonthGroup group;
  final _HistoryPalette palette;
  final ValueChanged<DailyScoreEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: GoogleFonts.kadwa(
                  color: palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              for (var index = 0; index < group.entries.length; index++) ...[
                _HistoryEntryCard(
                  entry: group.entries[index],
                  palette: palette,
                  onTap: () => onEntryTap(group.entries[index]),
                ),
                if (index < group.entries.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.palette,
    required this.onTap,
  });

  final DailyScoreEntry entry;
  final _HistoryPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scoreText = entry.average.toStringAsFixed(1).replaceAll('.', ',');
    final noteText = entry.note.isEmpty ? 'Not eklenmedi' : entry.note;

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.field,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.date.day.toString(),
                      style: GoogleFonts.kadwa(
                        color: palette.accent,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shortWeekday(entry.date),
                      style: GoogleFonts.kadwa(
                        color: palette.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.summaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kadwa(
                        color: palette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      noteText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kadwa(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    scoreText,
                    style: GoogleFonts.kadwa(
                      color: palette.accent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/10',
                    style: GoogleFonts.kadwa(
                      color: palette.muted,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.entry,
    required this.scoreText,
    required this.palette,
  });

  final DailyScoreEntry entry;
  final String scoreText;
  final _HistoryPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fullDate(entry.date),
            style: GoogleFonts.kadwa(
              color: palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scoreText,
                style: GoogleFonts.kadwa(
                  color: palette.accent,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3, bottom: 5),
                child: Text(
                  '/10',
                  style: GoogleFonts.kadwa(
                    color: palette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    entry.summaryLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.kadwa(
                      color: palette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.entry, required this.palette});

  final DailyScoreEntry entry;
  final _HistoryPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < dailyScoreQuestions.length; index++) ...[
            _ScoreRow(
              question: dailyScoreQuestions[index],
              score: entry.scores[dailyScoreQuestions[index].id],
              palette: palette,
            ),
            if (index < dailyScoreQuestions.length - 1)
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: palette.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.question,
    required this.score,
    required this.palette,
  });

  final DailyScoreQuestion question;
  final int? score;
  final _HistoryPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              question.shortTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kadwa(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score == null ? 0 : score! / 10,
                minHeight: 5,
                color: palette.accent,
                backgroundColor: palette.track,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            child: Text(
              score == null ? '--' : '$score',
              textAlign: TextAlign.right,
              style: GoogleFonts.kadwa(
                color: score == null ? palette.muted : palette.accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotePanel extends StatelessWidget {
  const _NotePanel({required this.note, required this.palette});

  final String note;
  final _HistoryPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        note.isEmpty ? 'Bu güne not eklenmedi.' : note,
        style: GoogleFonts.kadwa(
          color: note.isEmpty ? palette.muted : palette.text,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.palette});

  final String title;
  final _HistoryPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.kadwa(
        color: palette.text,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.palette,
    this.action,
  });

  final IconData icon;
  final String title;
  final _HistoryPalette palette;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.accent, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.kadwa(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}

class _MonthGroup {
  const _MonthGroup({required this.title, required this.entries});

  final String title;
  final List<DailyScoreEntry> entries;
}

class _HistoryPalette {
  const _HistoryPalette({
    required this.text,
    required this.muted,
    required this.surface,
    required this.field,
    required this.border,
    required this.track,
    required this.accent,
    required this.shadow,
  });

  final Color text;
  final Color muted;
  final Color surface;
  final Color field;
  final Color border;
  final Color track;
  final Color accent;
  final Color shadow;

  factory _HistoryPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HistoryPalette(
      text: isDark ? Colors.white : const Color(0xFF101828),
      muted: isDark ? const Color(0xFFA3A3A3) : const Color(0xFF667085),
      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      field: isDark ? const Color(0xFF262626) : const Color(0xFFF5F7F9),
      border: isDark ? const Color(0xFF343434) : const Color(0xFFE5EAF0),
      track: isDark ? const Color(0xFF303030) : const Color(0xFFEDF1F4),
      accent: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF111114),
      shadow: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
    );
  }
}

List<_MonthGroup> _groupByMonth(List<DailyScoreEntry> entries) {
  final grouped = <String, List<DailyScoreEntry>>{};

  for (final entry in entries) {
    final key = '${entry.date.year}-${entry.date.month}';
    grouped.putIfAbsent(key, () => <DailyScoreEntry>[]).add(entry);
  }

  return grouped.values
      .map(
        (monthEntries) => _MonthGroup(
          title: _monthTitle(monthEntries.first.date),
          entries: List<DailyScoreEntry>.unmodifiable(monthEntries),
        ),
      )
      .toList(growable: false);
}

String _monthTitle(DateTime date) {
  return '${_months[date.month - 1]} ${date.year}';
}

String _fullDate(DateTime date) {
  return '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';
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

const _weekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

const _shortWeekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
