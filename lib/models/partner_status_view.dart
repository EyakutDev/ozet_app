import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerStatusView {
  const PartnerStatusView({
    required this.icon,
    required this.text,
    required this.isActive,
  });

  static const Duration lifetime = Duration(hours: 24);

  final String icon;
  final String text;
  final bool isActive;

  factory PartnerStatusView.fromData(
    Map<String, dynamic>? data, {
    DateTime? now,
    String fallbackIcon = 'thinking',
    String fallbackText = 'Durum yok',
  }) {
    final currentTime = now ?? DateTime.now();
    final expiresAt =
        _readDate(data?['statusExpiresAt']) ??
        _readDate(data?['lastUpdated'])?.add(lifetime);
    final isActive = expiresAt == null || expiresAt.isAfter(currentTime);
    final icon = (data?['statusIcon'] as String?)?.trim();
    final text = (data?['statusText'] as String?)?.trim();
    final hasStatus = icon?.isNotEmpty == true || text?.isNotEmpty == true;

    if (!isActive || !hasStatus) {
      return PartnerStatusView(
        icon: fallbackIcon,
        text: fallbackText,
        isActive: false,
      );
    }

    return PartnerStatusView(
      icon: icon?.isNotEmpty == true ? icon! : fallbackIcon,
      text: text?.isNotEmpty == true ? text! : fallbackText,
      isActive: true,
    );
  }

  static DateTime expiresAtFrom(DateTime createdAt) => createdAt.add(lifetime);

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
