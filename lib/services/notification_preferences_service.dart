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
    await prefs.setBool(key, value);
    await sync(updated);
    return updated;
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
