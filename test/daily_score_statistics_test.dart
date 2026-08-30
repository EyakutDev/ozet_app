import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/models/daily_score_statistics.dart';

void main() {
  test('calculates rolling weekly metrics and previous-week difference', () {
    final statistics = DailyScoreStatistics.fromEntries([
      _entry(DateTime(2026, 7, 26), 8),
      _entry(DateTime(2026, 7, 24), 6),
      _entry(DateTime(2026, 7, 20), 4),
      _entry(DateTime(2026, 7, 19), 5),
      _entry(DateTime(2026, 7, 14), 3),
      _entry(DateTime(2026, 7, 12), 10),
      _entry(DateTime(2026, 7, 27), 10),
    ], now: DateTime(2026, 7, 26, 18));

    expect(statistics.points, hasLength(7));
    expect(statistics.points.first.date, DateTime(2026, 7, 20));
    expect(statistics.points.first.average, 4);
    expect(statistics.points[1].average, isNull);
    expect(statistics.points[4].average, 6);
    expect(statistics.points.last.average, 8);
    expect(statistics.completedDays, 3);
    expect(statistics.weeklyAverage, 6);
    expect(statistics.previousWeekAverage, 4);
    expect(statistics.weeklyDifference, 2);

    for (final question in dailyScoreQuestions) {
      expect(statistics.questionAverages[question.id], 6);
    }
  });

  test('keeps missing question and previous-week values unavailable', () {
    final statistics = DailyScoreStatistics.fromEntries([
      DailyScoreEntry(
        date: DateTime(2026, 7, 25),
        scores: const {'mood': 10, 'energy': 6},
        note: '',
      ),
    ], now: DateTime(2026, 7, 26));

    expect(statistics.completedDays, 1);
    expect(statistics.weeklyAverage, 8);
    expect(statistics.questionAverages['mood'], 10);
    expect(statistics.questionAverages['energy'], 6);
    expect(statistics.questionAverages['progress'], isNull);
    expect(statistics.previousWeekAverage, isNull);
    expect(statistics.weeklyDifference, isNull);
  });
  test('maps monthly entries into a monday-first calendar grid', () {
    final calendar = DailyScoreCalendarMonth.fromEntries([
      _entry(DateTime(2026, 7, 1), 6),
      _entry(DateTime(2026, 7, 26), 8),
      _entry(DateTime(2026, 8, 1), 10),
    ], DateTime(2026, 7, 18));

    expect(calendar.month, DateTime(2026, 7));
    expect(calendar.daysInMonth, 31);
    expect(calendar.leadingEmptyDays, 2);
    expect(calendar.entriesByDay.keys, containsAll([1, 26]));
    expect(calendar.entriesByDay[26]?.average, 8);
    expect(calendar.entriesByDay[1]?.average, 6);
    expect(calendar.entriesByDay, isNot(contains(32)));
    expect(DailyScoreCalendarMonth.totalCellCount, 42);
  });

  test('uses the correct day count for leap-year february', () {
    final calendar = DailyScoreCalendarMonth.fromEntries(
      const <DailyScoreEntry>[],
      DateTime(2024, 2),
    );

    expect(calendar.daysInMonth, 29);
    expect(calendar.leadingEmptyDays, 3);
  });
}

DailyScoreEntry _entry(DateTime date, int score) {
  return DailyScoreEntry(
    date: date,
    scores: {for (final question in dailyScoreQuestions) question.id: score},
    note: '',
  );
}
