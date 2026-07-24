import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/models/daily_score_entry.dart';

void main() {
  group('DailyScoreEntry', () {
    test('calculates the equal-weight daily average', () {
      final entry = DailyScoreEntry(
        date: DateTime(2026, 7, 16),
        scores: const {
          'mood': 8,
          'energy': 6,
          'progress': 7,
          'personal_time': 5,
          'calm': 9,
        },
        note: 'Sakin bir gündü.',
      );

      expect(entry.average, 7);
      expect(entry.summaryLabel, 'Dengeliydi');
      expect(entry.dateKey, '2026-07-16');
    });

    test('round-trips persisted values', () {
      final original = DailyScoreEntry(
        date: DateTime(2026, 7, 16, 21, 30),
        scores: const {
          'mood': 9,
          'energy': 8,
          'progress': 9,
          'personal_time': 7,
          'calm': 8,
        },
        note: 'İyi geçti.',
      );

      final restored = DailyScoreEntry.fromJson(original.toJson());

      expect(restored.date, original.date);
      expect(restored.scores, original.scores);
      expect(restored.note, original.note);
      expect(restored.questionSetVersion, 1);
      expect(restored.summaryLabel, 'İyi geçti');
    });
  });
}
