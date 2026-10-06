import 'package:cl_club_communication/src/utils/notification_registry.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

AppNotification _make(Map<String, dynamic> data) => AppNotification(
  id: 21,
  username: 'notif_admin',
  type: NotificationType.groupMemberIneligible,
  channel: NotificationChannel.inApp,
  payload: <String, dynamic>{
    'v': 1,
    'type': NotificationType.groupMemberIneligible,
    'data': data,
  },
  isRead: false,
  createdAtUtc: DateTime.utc(2026, 10, 6),
);

const _data = <String, dynamic>{
  'groupId': 5,
  'groupName': 'Juniors',
  'membername': 'workflow_member',
};

void main() {
  group('Issue 33: group.member_ineligible', () {
    test('Issue 33: the SDK type has a registry row', () {
      expect(
        kNotificationKindByType,
        contains(NotificationType.groupMemberIneligible),
      );
    });

    test('Issue 33: names the group and the member', () {
      final d = formatNotification(_make(_data));
      expect(d.title, 'Juniors');
      expect(
        d.body,
        '@workflow_member no longer meets the eligibility criteria of '
        'Juniors.',
      );
      expect(d.icon, LucideIcons.userX);
      expect(
        notificationTypeLabel(NotificationType.groupMemberIneligible),
        'Member no longer eligible',
      );
    });

    test('Issue 33: a payload without names still reads as a sentence', () {
      final d = formatNotification(_make(const {'groupId': 5}));
      expect(d.title, 'Group');
      expect(
        d.body,
        'A member no longer meets the eligibility criteria of the group.',
      );
    });

    test('Issue 33: opens that group', () {
      final link = resolveDeepLink(
        _make(_data),
        currentUsername: 'notif_admin',
      );
      expect(link, isA<NotifGroupLink>());
      final groupLink = link! as NotifGroupLink;
      expect(groupLink.groupId, 5);
      expect(groupLink.sourceNotificationId, 21);
    });

    test('Issue 33: with no group in the payload there is nothing to open', () {
      final link = resolveDeepLink(
        _make(const {'membername': 'workflow_member'}),
        currentUsername: 'notif_admin',
      );
      expect(link, isNull);
    });
  });
}
