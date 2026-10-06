import 'notification_payload.dart';
import 'notification_payload_key.dart';
import 'notification_registry.dart';

/// The staff view of the member a notification is about (the payload's
/// `membername`), or `null` when the payload names none.
///
/// The no-longer-eligible notifications (`enrollment.member_ineligible`,
/// `group.member_ineligible`) are each about one member, so they open that
/// member's profile, whose Events and Groups sections mark what the member
/// no longer matches (club_client#43).
NotificationDeepLink? memberProfileLink(NotificationLinkContext ctx) {
  final membername = payloadString(ctx.data[NotificationPayloadKey.membername]);
  return membername.isEmpty
      ? null
      : NotifAdminUserLink(
          membername,
          sourceNotificationId: ctx.sourceNotificationId,
        );
}
