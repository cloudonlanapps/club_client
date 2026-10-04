import 'package:club_sdk_2/club_sdk_2.dart' show NotificationType;
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'notification_payload.dart';
import 'notification_payload_key.dart';
import 'notification_registry.dart';

/// Registry rows for a programme's end moving: `event.terminated` and
/// `event.extended` (club_core#32). The server sends both to the event's
/// enrollees, coaches and organiser, so they open the member's own view of
/// the event, like the rest of the event family.
final List<NotificationKind> kProgrammeNotificationKinds = <NotificationKind>[
  const NotificationKind(
    type: NotificationType.eventTerminated,
    typeLabel: 'Programme terminated',
    format: formatEventTerminated,
    deepLink: myEventLink,
  ),
  const NotificationKind(
    type: NotificationType.eventExtended,
    typeLabel: 'Programme extended',
    format: formatEventExtended,
    deepLink: myEventLink,
  ),
];

/// `event.terminated`: the programme, its last day and the reason.
NotificationDisplay formatEventTerminated(Map<String, dynamic> data) {
  final title = payloadString(data[NotificationPayloadKey.eventTitle]);
  final day = payloadDateText(data[NotificationPayloadKey.cutoffTimeUtc]);
  final reason = payloadString(data[NotificationPayloadKey.reason]);
  final lead = day.isNotEmpty ? '$title ends on $day' : '$title was terminated';
  return NotificationDisplay(
    title: title.isNotEmpty ? title : 'Programme terminated',
    body: reason.isNotEmpty ? '$lead: $reason.' : '$lead.',
    icon: LucideIcons.calendarOff,
  );
}

/// `event.extended`: the programme and its new last day, or none when the
/// cutoff was cleared.
NotificationDisplay formatEventExtended(Map<String, dynamic> data) {
  final title = payloadString(data[NotificationPayloadKey.eventTitle]);
  final day = payloadDateText(data[NotificationPayloadKey.cutoffTimeUtc]);
  final reason = payloadString(data[NotificationPayloadKey.reason]);
  final lead = day.isNotEmpty
      ? '$title now ends on $day'
      : '$title no longer has an end date';
  return NotificationDisplay(
    title: title.isNotEmpty ? title : 'Programme extended',
    body: reason.isNotEmpty ? '$lead: $reason.' : '$lead.',
    icon: LucideIcons.calendarPlus,
  );
}
