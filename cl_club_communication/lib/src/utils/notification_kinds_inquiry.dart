import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind, NotificationType;
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'notification_payload.dart';
import 'notification_payload_key.dart';
import 'notification_registry.dart';

/// Registry row for `inquiry.received` (club_core#32): the server sends one
/// to every admin when the public website stores an inquiry, and a tap
/// opens the admin inquiries inbox.
final List<NotificationKind> kInquiryNotificationKinds = <NotificationKind>[
  const NotificationKind(
    type: NotificationType.inquiryReceived,
    typeLabel: 'Inquiry',
    format: formatInquiryReceived,
    deepLink: inquiriesLink,
  ),
];

/// `inquiry.received`: who wrote, and whether it is a message or an
/// expression of interest.
NotificationDisplay formatInquiryReceived(Map<String, dynamic> data) {
  final name = payloadString(data[NotificationPayloadKey.name]);
  // The name comes from the public website: shown literally, never as
  // markdown.
  final who = name.isNotEmpty ? markdownLiteral(name) : 'Someone';
  final kind = InquiryKind.fromWire(
    payloadString(data[NotificationPayloadKey.kind]),
  );
  return NotificationDisplay(
    title: 'New inquiry',
    body: switch (kind) {
      InquiryKind.contact => '$who sent a message.',
      InquiryKind.interest => '$who registered interest.',
    },
    icon: LucideIcons.inbox,
  );
}

/// Every `inquiry.received` opens the inbox; the row's id is not needed.
NotificationDeepLink? inquiriesLink(NotificationLinkContext ctx) =>
    NotifInquiriesLink(sourceNotificationId: ctx.sourceNotificationId);
