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
  test('remembers that the notification permission offer was shown', () async {
    SharedPreferences.setMockInitialValues({});

    final service = NotificationPreferencesService();
    expect(await service.hasPermissionPromptBeenShown(), isFalse);

    await service.markPermissionPromptShown();

    expect(await service.hasPermissionPromptBeenShown(), isTrue);
  });

  test('rolls back the local value when remote sync fails', () async {
    SharedPreferences.setMockInitialValues({
      NotificationPreferencesService.morningKey: true,
    });
    final service = _FailingSyncNotificationPreferencesService();

    await expectLater(
      service.update(NotificationPreferencesService.morningKey, false),
      throwsA(isA<StateError>()),
    );

    final restored = await service.load();
    expect(restored.morningDigest, isTrue);
  });
}

class _FailingSyncNotificationPreferencesService
    extends NotificationPreferencesService {
  @override
  Future<void> sync([NotificationPreferences? preferences]) async {
    throw StateError('Remote sync failed.');
  }
}
