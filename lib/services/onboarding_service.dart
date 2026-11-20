import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const completedKey = 'onboardingCompletedV1';

  Future<bool> hasCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completedKey) ?? false;
  }

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(completedKey, true);
    if (!saved) throw StateError('Onboarding tercihi kaydedilemedi.');
  }
}
