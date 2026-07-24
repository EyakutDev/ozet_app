import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:ozet_app/services/daily_score_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const userId = 'history-test-user';
  const storageKey = 'daily_score_entries_v1_$userId';

  late DailyScoreStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = DailyScoreStorage(userIdProvider: () => userId);
  });

  test('returns saved entries from newest to oldest', () async {
    await storage.save(_entry(DateTime(2026, 7, 15), 6));
    await storage.save(_entry(DateTime(2026, 7, 18), 8));
    await storage.save(_entry(DateTime(2026, 7, 16), 7));

    final entries = await storage.getAll();

    expect(entries.map((entry) => entry.dateKey), [
      '2026-07-18',
      '2026-07-16',
      '2026-07-15',
    ]);
  });

  test('skips malformed records without hiding valid history', () async {
    final validEntry = _entry(DateTime(2026, 7, 18), 8);
    SharedPreferences.setMockInitialValues({
      storageKey: jsonEncode({
        validEntry.dateKey: validEntry.toJson(),
        'broken-date': {
          'date': 'not-a-date',
          'scores': const {'mood': 5},
          'note': '',
        },
        'wrong-shape': 'invalid',
      }),
    });

    final entries = await storage.getAll();

    expect(entries, hasLength(1));
    expect(entries.single.dateKey, validEntry.dateKey);
  });
}

DailyScoreEntry _entry(DateTime date, int score) {
  return DailyScoreEntry(
    date: date,
    scores: {for (final question in dailyScoreQuestions) question.id: score},
    note: 'Test notu',
  );
}
