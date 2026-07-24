import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:ozet_app/models/daily_score_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyScoreStorage {
  DailyScoreStorage({String Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  static const _storagePrefix = 'daily_score_entries_v1';
  final String Function()? _userIdProvider;

  String get _storageKey {
    final userId =
        _userIdProvider?.call() ??
        FirebaseAuth.instance.currentUser?.uid ??
        'guest';
    return '${_storagePrefix}_$userId';
  }

  Future<DailyScoreEntry?> getForDate(DateTime date) async {
    final entries = await _readEntries();
    return _parseEntry(entries[DailyScoreEntry.keyFor(date)]);
  }

  Future<List<DailyScoreEntry>> getAll() async {
    final entries = await _readEntries();
    final parsedEntries = <DailyScoreEntry>[];

    for (final rawEntry in entries.values) {
      final entry = _parseEntry(rawEntry);
      if (entry != null) parsedEntries.add(entry);
    }

    parsedEntries.sort((a, b) => b.date.compareTo(a.date));
    return List<DailyScoreEntry>.unmodifiable(parsedEntries);
  }

  Future<void> save(DailyScoreEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _readEntries();
    entries[entry.dateKey] = entry.toJson();

    final saved = await prefs.setString(_storageKey, jsonEncode(entries));
    if (!saved) {
      throw StateError('Günün puanı cihazda saklanamadı.');
    }
  }

  Future<Map<String, dynamic>> _readEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_storageKey);
    if (rawValue == null || rawValue.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Bozuk yerel veri yeni kayıtların oluşturulmasını engellememeli.
    }

    return <String, dynamic>{};
  }

  DailyScoreEntry? _parseEntry(Object? rawEntry) {
    if (rawEntry is! Map) return null;

    try {
      return DailyScoreEntry.fromJson(Map<String, dynamic>.from(rawEntry));
    } on Object {
      return null;
    }
  }
}
