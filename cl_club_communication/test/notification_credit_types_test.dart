import 'package:cl_club_communication/src/utils/notification_deep_link.dart';
import 'package:cl_club_communication/src/utils/notification_formatter.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

AppNotification _make(String type, Map<String, dynamic> data) =>
    AppNotification(
      id: 7,
      username: 'credit_member',
      type: type,
      channel: NotificationChannel.inApp,
      payload: <String, dynamic>{'v': 1, 'type': type, 'data': data},
      isRead: false,
      createdAtUtc: DateTime.utc(2026, 9, 26),
    );

void main() {
  group('Issue 100: enrollment.trial_ended', () {
    final n = _make('enrollment.trial_ended', {
      'eventId': 9,
      'eventTitle': 'Skating',
      'eventType': 'programme',
      'enrolledAtUtc': DateTime(2026, 9, 12, 12).millisecondsSinceEpoch,
      'withdrawnAtUtc': DateTime(2026, 9, 23, 12).millisecondsSinceEpoch,
    });

    test('Issue 100: a flag, the programme and the trial dates', () {
      final d = formatNotification(n);
      expect(d.title, 'Skating');
      expect(d.body, '12 Sep – 23 Sep');
      expect(d.icon, LucideIcons.flag);
    });

    test('Issue 100: opens the member event', () {
      final link = resolveDeepLink(n, currentUsername: 'credit_member');
      expect(link, isA<NotifMyEventLink>());
    });
  });

  group('Issue 32: credit.released', () {
    final n = _make('credit.released', {
      'eventId': 9,
      'eventTitle': 'Skating',
      'credits': 4,
    });

    test('Issue 32: coins, the programme and the amount', () {
      final d = formatNotification(n);
      expect(d.title, 'Skating');
      expect(d.body, '+4');
      expect(d.icon, LucideIcons.coins);
    });

    test('Issue 32: opens the member credit view', () {
      final link = resolveDeepLink(n, currentUsername: 'credit_member');
      expect(link, isA<NotifCreditLink>());
      expect((link! as NotifCreditLink).username, 'credit_member');
    });
  });
}
