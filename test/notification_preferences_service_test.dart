import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/services/notification_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('migrates the old evening summary preference', () async {
    SharedPreferences.setMockInitialValues({
      'gununOzeti': false,
      'aksamOzeti': false,
    });

    final preferences = await NotificationPreferencesService().load();

    expect(preferences.morningDigest, isFalse);
    expect(preferences.eveningCheckIn, isFalse);
    expect(preferences.partnerUpdates, isTrue);
  });
}
