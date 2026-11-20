import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.morningDigest,
    required this.eveningCheckIn,
    required this.partnerUpdates,
  });

  final bool morningDigest;
  final bool eveningCheckIn;
  final bool partnerUpdates;

  NotificationPreferences copyWith({
    bool? morningDigest,
    bool? eveningCheckIn,
    bool? partnerUpdates,
  }) {
    return NotificationPreferences(
      morningDigest: morningDigest ?? this.morningDigest,
      eveningCheckIn: eveningCheckIn ?? this.eveningCheckIn,
      partnerUpdates: partnerUpdates ?? this.partnerUpdates,
    );
  }
}

enum AppNotificationPermission { notDetermined, granted, denied }

class NotificationPreferencesService {
  NotificationPreferencesService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  }) : _auth = auth,
       _firestore = firestore,
       _messaging = messaging;

  static const String morningKey = 'gununOzeti';
  static const String eveningKey = 'aksamHatirlatmasi';
  static const String partnerKey = 'partnerBildirimleri';
  static const String permissionPromptShownKey =
      'notificationPermissionPromptShown';

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseMessaging? _messaging;

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      morningDigest: prefs.getBool(morningKey) ?? true,
      eveningCheckIn:
          prefs.getBool(eveningKey) ?? prefs.getBool('aksamOzeti') ?? true,
      partnerUpdates: prefs.getBool(partnerKey) ?? true,
    );
  }

  Future<NotificationPreferences> update(String key, bool value) async {
    final current = await load();
    final updated = switch (key) {
      morningKey => current.copyWith(morningDigest: value),
      eveningKey => current.copyWith(eveningCheckIn: value),
      partnerKey => current.copyWith(partnerUpdates: value),
      _ => throw ArgumentError.value(key, 'key', 'Bilinmeyen bildirim ayarı'),
    };

    final prefs = await SharedPreferences.getInstance();
    final previousValue = switch (key) {
      morningKey => current.morningDigest,
      eveningKey => current.eveningCheckIn,
      partnerKey => current.partnerUpdates,
      _ => value,
    };
    final saved = await prefs.setBool(key, value);
    if (!saved) {
      throw StateError('Bildirim tercihi cihazda saklanamadı.');
    }

    try {
      await sync(updated);
    } catch (_) {
      await prefs.setBool(key, previousValue);
      rethrow;
    }
    return updated;
  }

  Future<AppNotificationPermission> permissionState() async {
    final messaging = _messaging ?? FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  Future<bool> hasPermissionPromptBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(permissionPromptShownKey) ?? false;
  }

  Future<bool> shouldOfferPermissionPrompt() async {
    if (await hasPermissionPromptBeenShown()) return false;
    return await permissionState() == AppNotificationPermission.notDetermined;
  }

  Future<void> markPermissionPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(permissionPromptShownKey, true);
    if (!saved) {
      throw StateError('Bildirim izin tercihi cihazda saklanamadı.');
    }
  }

  Future<AppNotificationPermission> requestPermissionAndConfigure() async {
    await markPermissionPromptShown();
    final messaging = _messaging ?? FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final state = _mapAuthorizationStatus(settings.authorizationStatus);
    if (state == AppNotificationPermission.granted) {
      await messaging.subscribeToTopic('all');
      await sync();
    }
    return state;
  }

  Future<bool> configureIfAuthorized() async {
    if (await permissionState() != AppNotificationPermission.granted) {
      return false;
    }
    final messaging = _messaging ?? FirebaseMessaging.instance;
    await messaging.subscribeToTopic('all');
    await sync();
    return true;
  }

  AppNotificationPermission _mapAuthorizationStatus(
    AuthorizationStatus status,
  ) {
    return switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => AppNotificationPermission.granted,
      AuthorizationStatus.notDetermined =>
        AppNotificationPermission.notDetermined,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => AppNotificationPermission.denied,
    };
  }

  Future<void> sync([NotificationPreferences? preferences]) async {
    final current = preferences ?? await load();
    await Future.wait([
      _setTopic('daily_digest', current.morningDigest),
      _setTopic('evening_checkin', current.eveningCheckIn),
    ]);

    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) return;
    await (_firestore ?? FirebaseFirestore.instance)
        .collection('user_private')
        .doc(user.uid)
        .set({
          'notificationPreferences': {
            'morningDigest': current.morningDigest,
            'eveningCheckIn': current.eveningCheckIn,
            'partnerUpdates': current.partnerUpdates,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _setTopic(String topic, bool enabled) {
    final messaging = _messaging ?? FirebaseMessaging.instance;
    return enabled
        ? messaging.subscribeToTopic(topic)
        : messaging.unsubscribeFromTopic(topic);
  }
}
