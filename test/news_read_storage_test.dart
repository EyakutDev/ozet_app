import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/services/news_read_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('stores read news ids without duplicates', () async {
    final storage = NewsReadStorage(userIdProvider: () => 'user-1');

    await storage.markRead('news-1');
    await storage.markRead('news-2');
    await storage.markRead('news-1');

    expect(await storage.getReadIds(), {'news-1', 'news-2'});
  });

  test('keeps read state separate for each user and guest', () async {
    final userStorage = NewsReadStorage(userIdProvider: () => 'user-1');
    final otherStorage = NewsReadStorage(userIdProvider: () => 'user-2');
    final guestStorage = NewsReadStorage(userIdProvider: () => 'guest');

    await userStorage.markRead('user-news');
    await guestStorage.markRead('guest-news');

    expect(await userStorage.getReadIds(), {'user-news'});
    expect(await otherStorage.getReadIds(), isEmpty);
    expect(await guestStorage.getReadIds(), {'guest-news'});
  });

  test('keeps only the most recent read ids', () async {
    final storage = NewsReadStorage(userIdProvider: () => 'user-1');

    for (var index = 0; index <= NewsReadStorage.maxStoredNewsIds; index++) {
      await storage.markRead('news-$index');
    }

    final readIds = await storage.getReadIds();
    expect(readIds, hasLength(NewsReadStorage.maxStoredNewsIds));
    expect(readIds, contains('news-${NewsReadStorage.maxStoredNewsIds}'));
    expect(readIds, isNot(contains('news-0')));
  });
}
