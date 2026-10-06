import 'package:club_sdk_2/club_sdk_2.dart' show NotificationType;
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'notification_payload.dart';
import 'notification_payload_key.dart';
import 'notification_registry.dart';

/// Registry row for `group.member_ineligible` (club_client#33,
/// club_server#17): the server sends one to every admin, once, when a
/// semi-auto member stops meeting the group's criteria. Nobody is removed,
/// so a tap opens the group, where the member is marked in the member list.
final List<NotificationKind> kGroupEligibilityNotificationKinds =
    <NotificationKind>[
      const NotificationKind(
        type: NotificationType.groupMemberIneligible,
        typeLabel: 'Member no longer eligible',
        format: formatGroupMemberIneligible,
        deepLink: groupProfileLink,
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

/// The admin's view of the payload's group, or `null` when the payload names
/// none.
NotificationDeepLink? groupProfileLink(NotificationLinkContext ctx) {
  final id = payloadInt(ctx.data[NotificationPayloadKey.groupId]);
  return id == null
      ? null
      : NotifGroupLink(id, sourceNotificationId: ctx.sourceNotificationId);
}
