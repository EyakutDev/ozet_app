class DailyScoreQuestion {
  const DailyScoreQuestion({
    required this.id,
    required this.title,
    required this.shortTitle,
  });

  final String id;
  final String title;
  final String shortTitle;
}

const dailyScoreQuestions = <DailyScoreQuestion>[
  DailyScoreQuestion(
    id: 'mood',
    title: 'Bugün ruh halin nasıldı?',
    shortTitle: 'Ruh hali',
  ),
  DailyScoreQuestion(
    id: 'energy',
    title: 'Enerjin ne kadar yüksekti?',
    shortTitle: 'Enerji',
  ),
  DailyScoreQuestion(
    id: 'progress',
    title: 'Yapmak istediklerini ne ölçüde tamamladın?',
    shortTitle: 'İlerleme',
  ),
  DailyScoreQuestion(
    id: 'personal_time',
    title: 'Kendine yeterince zaman ayırabildin mi?',
    shortTitle: 'Kendine zaman',
  ),
  DailyScoreQuestion(
    id: 'calm',
    title: 'Gün boyunca ne kadar huzurluydun?',
    shortTitle: 'Huzur',
  ),
];

class DailyScoreEntry {
  const DailyScoreEntry({
    required this.date,
    required this.scores,
    required this.note,
    this.questionSetVersion = 1,
  });

  final DateTime date;
  final Map<String, int> scores;
  final String note;
  final int questionSetVersion;

  double get average {
    if (scores.isEmpty) return 0;
    final total = scores.values.fold<int>(0, (sum, value) => sum + value);
    return total / scores.length;
  }

  String get summaryLabel {
    if (average < 4) return 'Zor geçti';
    if (average < 6) return 'Karışıktı';
    if (average < 8) return 'Dengeliydi';
    return 'İyi geçti';
  }

  String get dateKey => keyFor(date);

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'scores': scores,
      'note': note,
      'questionSetVersion': questionSetVersion,
    };
  }

  factory DailyScoreEntry.fromJson(Map<String, dynamic> json) {
    final rawScores = json['scores'];
    final scores = <String, int>{};

    if (rawScores is Map) {
      for (final entry in rawScores.entries) {
        final value = entry.value;
        if (value is num) scores[entry.key.toString()] = value.toInt();
      }
    }

    return DailyScoreEntry(
      date: DateTime.parse(json['date'] as String),
      scores: scores,
      note: (json['note'] as String?) ?? '',
      questionSetVersion: (json['questionSetVersion'] as num?)?.toInt() ?? 1,
    );
  }

  static String keyFor(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
