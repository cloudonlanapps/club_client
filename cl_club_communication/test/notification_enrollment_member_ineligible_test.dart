import 'package:cl_club_communication/src/utils/notification_registry.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

AppNotification _make(Map<String, dynamic> data) => AppNotification(
  id: 23,
  username: 'notif_admin',
  type: NotificationType.enrollmentMemberIneligible,
  channel: NotificationChannel.inApp,
  payload: <String, dynamic>{
    'v': 1,
    'type': NotificationType.enrollmentMemberIneligible,
    'data': data,
  },
  isRead: false,
  createdAtUtc: DateTime.utc(2026, 10, 6),
);

// The keys club_server's daily scan writes (club_server#19).
const _data = <String, dynamic>{
  'eventId': 9,
  'eventTitle': 'Skating',
  'membername': 'workflow_member',
};

void main() {
  group('Issue 42: enrollment.member_ineligible', () {
    test('Issue 42: the SDK type has a registry row', () {
      expect(
        kNotificationKindByType,
        contains(NotificationType.enrollmentMemberIneligible),
      );
    });

    test('Issue 42: names the programme and the member', () {
      final d = formatNotification(_make(_data));
      expect(d.title, 'Skating');
      expect(
        d.body,
        '@workflow_member no longer meets the eligibility criteria of '
        'Skating.',
      );
      expect(d.icon, LucideIcons.userX);
      expect(
        notificationTypeLabel(NotificationType.enrollmentMemberIneligible),
        'Member no longer eligible',
      );
    });

    test('Issue 42: a payload without names still reads as a sentence', () {
      final d = formatNotification(_make(const {'eventId': 9}));
      expect(d.title, 'Programme');
      expect(
        d.body,
        'A member no longer meets the eligibility criteria of the programme.',
      );
    });

    test('Issue 42: opens that programme in the staff view', () {
      final link = resolveDeepLink(
        _make(_data),
        currentUsername: 'notif_admin',
      );
      expect(link, isA<NotifEventLink>());
      final eventLink = link! as NotifEventLink;
      expect(eventLink.eventId, 9);
      expect(eventLink.sourceNotificationId, 23);
    });

    test('Issue 42: with no programme in the payload there is nothing to '
        'open', () {
      final link = resolveDeepLink(
        _make(const {'membername': 'workflow_member'}),
        currentUsername: 'notif_admin',
      );
      expect(link, isNull);
    });
  });
}
