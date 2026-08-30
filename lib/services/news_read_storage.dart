import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haberlerin okundu durumunu Firestore verisini değiştirmeden cihazda saklar.
class NewsReadStorage {
  NewsReadStorage({String Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  static const _storagePrefix = 'news_read_ids_v1';
  static const maxStoredNewsIds = 500;

  final String Function()? _userIdProvider;

  String get _storageKey {
    final userId =
        _userIdProvider?.call() ??
        FirebaseAuth.instance.currentUser?.uid ??
        'guest';
    return '${_storagePrefix}_$userId';
  }

  Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? const <String>[];
    return ids.where((id) => id.trim().isNotEmpty).toSet();
  }

  Future<void> markRead(String newsId) async {
    final normalizedId = newsId.trim();
    if (normalizedId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? <String>[];

    // Son okunan haberi basa alarak eski kayitlari sinirli tutariz.
    ids
      ..remove(normalizedId)
      ..insert(0, normalizedId);
    if (ids.length > maxStoredNewsIds) {
      ids.removeRange(maxStoredNewsIds, ids.length);
    }

    final saved = await prefs.setStringList(_storageKey, ids);
    if (!saved) {
      throw StateError('Okundu bilgisi cihazda saklanamadi.');
    }
  }
}
