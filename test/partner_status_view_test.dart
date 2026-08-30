import 'package:flutter_test/flutter_test.dart';
import 'package:ozet_app/models/partner_status_view.dart';

void main() {
  test('keeps a partner status active for 24 hours', () {
    final now = DateTime(2026, 8, 30, 12);
    final status = PartnerStatusView.fromData({
      'statusIcon': 'chat',
      'statusText': 'Konuşalım',
      'statusExpiresAt': now.add(const Duration(minutes: 1)),
    }, now: now);

    expect(status.isActive, isTrue);
    expect(status.text, 'Konuşalım');
  });

  test('returns the neutral state when a partner status expires', () {
    final now = DateTime(2026, 8, 30, 12);
    final status = PartnerStatusView.fromData({
      'statusIcon': 'chat',
      'statusText': 'Konuşalım',
      'statusExpiresAt': now.subtract(const Duration(seconds: 1)),
    }, now: now);

    expect(status.isActive, isFalse);
    expect(status.text, 'Durum yok');
  });
}
