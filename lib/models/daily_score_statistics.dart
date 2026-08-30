import 'package:ozet_app/models/daily_score_entry.dart';

class DailyScoreDayPoint {
  const DailyScoreDayPoint({required this.date, required this.average});

  final DateTime date;
  final double? average;
}

class DailyScoreCalendarMonth {
  const DailyScoreCalendarMonth({
    required this.month,
    required this.daysInMonth,
    required this.leadingEmptyDays,
    required this.entriesByDay,
  });

  factory DailyScoreCalendarMonth.fromEntries(
    Iterable<DailyScoreEntry> entries,
    DateTime month,
  ) {
    final normalizedMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final entriesByDay = <int, DailyScoreEntry>{};

    for (final entry in entries) {
      if (entry.date.year != month.year || entry.date.month != month.month) {
        continue;
      }
      entriesByDay[entry.date.day] = entry;
    }

    return DailyScoreCalendarMonth(
      month: normalizedMonth,
      daysInMonth: daysInMonth,
      leadingEmptyDays: normalizedMonth.weekday - DateTime.monday,
      entriesByDay: Map<int, DailyScoreEntry>.unmodifiable(entriesByDay),
    );
  }

  static const totalCellCount = 42;

  final DateTime month;
  final int daysInMonth;
  final int leadingEmptyDays;
  final Map<int, DailyScoreEntry> entriesByDay;
}

class DailyScoreStatistics {
  const DailyScoreStatistics({
    required this.points,
    required this.weeklyAverage,
    required this.completedDays,
    required this.questionAverages,
    required this.previousWeekAverage,
    required this.weeklyDifference,
  });

  factory DailyScoreStatistics.fromEntries(
    Iterable<DailyScoreEntry> entries, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final firstCurrentDay = today.subtract(const Duration(days: 6));
    final firstPreviousDay = today.subtract(const Duration(days: 13));
    final entriesByDate = <String, DailyScoreEntry>{};

    for (final entry in entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (date.isBefore(firstPreviousDay) || date.isAfter(today)) continue;
      entriesByDate[DailyScoreEntry.keyFor(date)] = entry;
    }

    final currentEntries = <DailyScoreEntry>[];
    final points = List<DailyScoreDayPoint>.generate(7, (index) {
      final date = firstCurrentDay.add(Duration(days: index));
      final entry = entriesByDate[DailyScoreEntry.keyFor(date)];
      if (entry != null) currentEntries.add(entry);
      return DailyScoreDayPoint(date: date, average: entry?.average);
    });
    final previousEntries = List<DailyScoreEntry?>.generate(7, (index) {
      final date = firstPreviousDay.add(Duration(days: index));
      return entriesByDate[DailyScoreEntry.keyFor(date)];
    }).whereType<DailyScoreEntry>().toList(growable: false);

    final weeklyAverage = _entryAverage(currentEntries);
    final previousWeekAverage = _entryAverage(previousEntries);
    final questionAverages = <String, double>{};

    for (final question in dailyScoreQuestions) {
      final values = currentEntries
          .map((entry) => entry.scores[question.id])
          .whereType<int>()
          .toList(growable: false);
      if (values.isEmpty) continue;
      questionAverages[question.id] =
          values.fold<int>(0, (sum, value) => sum + value) / values.length;
    }

    return DailyScoreStatistics(
      points: List<DailyScoreDayPoint>.unmodifiable(points),
      weeklyAverage: weeklyAverage,
      completedDays: currentEntries.length,
      questionAverages: Map<String, double>.unmodifiable(questionAverages),
      previousWeekAverage: previousWeekAverage,
      weeklyDifference: weeklyAverage == null || previousWeekAverage == null
          ? null
          : weeklyAverage - previousWeekAverage,
    );
  }

  final List<DailyScoreDayPoint> points;
  final double? weeklyAverage;
  final int completedDays;
  final Map<String, double> questionAverages;
  final double? previousWeekAverage;
  final double? weeklyDifference;
}

double? _entryAverage(List<DailyScoreEntry> entries) {
  if (entries.isEmpty) return null;
  return entries.fold<double>(0, (sum, entry) => sum + entry.average) /
      entries.length;
}
