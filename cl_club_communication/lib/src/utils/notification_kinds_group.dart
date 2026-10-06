import 'package:club_sdk_2/club_sdk_2.dart' show NotificationType;
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'notification_member_link.dart';
import 'notification_payload.dart';
import 'notification_payload_key.dart';
import 'notification_registry.dart';

/// Registry row for `group.member_ineligible` (club_client#33,
/// club_server#17): the server sends one to every admin, once, when a
/// semi-auto member stops meeting the group's criteria. Nobody is removed.
/// It is about one member, so a tap opens that member's profile, whose
/// Groups section marks the group (club_client#43).
final List<NotificationKind> kGroupEligibilityNotificationKinds =
    <NotificationKind>[
      const NotificationKind(
        type: NotificationType.groupMemberIneligible,
        typeLabel: 'Member no longer eligible',
        format: formatGroupMemberIneligible,
        deepLink: memberProfileLink,
      ),
    ];

/// `group.member_ineligible`: the group and the member who stopped matching.
NotificationDisplay formatGroupMemberIneligible(Map<String, dynamic> data) {
  final groupName = payloadString(data[NotificationPayloadKey.groupName]);
  final membername = payloadString(data[NotificationPayloadKey.membername]);
  final who = membername.isNotEmpty ? '@$membername' : 'A member';
  final where = groupName.isNotEmpty ? groupName : 'the group';
  return NotificationDisplay(
    title: groupName.isNotEmpty ? groupName : 'Group',
    body: '$who no longer meets the eligibility criteria of $where.',
    icon: LucideIcons.userX,
  );
}
