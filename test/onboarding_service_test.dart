import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'onboarding is incomplete until the user finishes or skips it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService();

      expect(await service.hasCompleted(), isFalse);

      await service.complete();

      expect(await service.hasCompleted(), isTrue);
    },
  );
}
