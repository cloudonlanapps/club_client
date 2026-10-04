import 'package:club_sdk_2/club_sdk_2.dart' show NotificationType;
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'notification_payload.dart';
import 'notification_payload_key.dart';
import 'notification_registry.dart';

/// Registry rows for the evaluation lifecycle (club_core#32, #174).
///
/// `evaluation.published` and `evaluation.withdrawn` reach the member the
/// evaluation is about, who reads it as a *review*: published opens it,
/// withdrawn opens their reviews (it can no longer be read).
/// `evaluation.transferred` reaches the coach who now owns it and opens it
/// in their editor.
final List<NotificationKind> kEvaluationNotificationKinds = <NotificationKind>[
  const NotificationKind(
    type: NotificationType.evaluationPublished,
    typeLabel: 'Review',
    format: formatEvaluationPublished,
    deepLink: myReviewLink,
  ),
  const NotificationKind(
    type: NotificationType.evaluationWithdrawn,
    typeLabel: 'Review',
    format: formatEvaluationWithdrawn,
    deepLink: myReviewsLink,
  ),
  const NotificationKind(
    type: NotificationType.evaluationTransferred,
    typeLabel: 'Evaluation',
    format: formatEvaluationTransferred,
    deepLink: evaluationLink,
  ),
];

/// `evaluation.published`: the coach, when the payload names one.
NotificationDisplay formatEvaluationPublished(Map<String, dynamic> data) {
  final owner = payloadString(data[NotificationPayloadKey.owner]);
  return NotificationDisplay(
    title: 'Review published',
    body: owner.isNotEmpty
        ? 'A new review from @$owner is ready to read.'
        : 'A new review is ready to read.',
    icon: LucideIcons.fileCheck,
  );
}

/// `evaluation.withdrawn`: the payload carries only the evaluation's id.
NotificationDisplay formatEvaluationWithdrawn(Map<String, dynamic> data) =>
    const NotificationDisplay(
      title: 'Review withdrawn',
      body: 'A review of you was withdrawn.',
      icon: LucideIcons.fileMinus,
    );

/// `evaluation.transferred`: the member and the previous owner.
NotificationDisplay formatEvaluationTransferred(Map<String, dynamic> data) {
  final member = payloadString(data[NotificationPayloadKey.createdFor]);
  final from = payloadString(data[NotificationPayloadKey.fromOwner]);
  final what = member.isNotEmpty
      ? 'The evaluation of @$member'
      : 'An evaluation';
  return NotificationDisplay(
    title: 'Evaluation transferred',
    body: from.isNotEmpty
        ? '$what was handed to you by @$from.'
        : '$what was handed to you.',
    icon: LucideIcons.arrowRightLeft,
  );
}

/// `evaluation.published` → the member's review; none without an id.
NotificationDeepLink? myReviewLink(NotificationLinkContext ctx) {
  final id = payloadInt(ctx.data[NotificationPayloadKey.evaluationId]);
  return id == null
      ? null
      : NotifMyReviewLink(id, sourceNotificationId: ctx.sourceNotificationId);
}

/// `evaluation.withdrawn` → the member's reviews.
NotificationDeepLink? myReviewsLink(NotificationLinkContext ctx) =>
    NotifMyReviewsLink(sourceNotificationId: ctx.sourceNotificationId);

/// `evaluation.transferred` → the evaluation in its new owner's editor;
/// none without an id.
NotificationDeepLink? evaluationLink(NotificationLinkContext ctx) {
  final id = payloadInt(ctx.data[NotificationPayloadKey.evaluationId]);
  return id == null
      ? null
      : NotifEvaluationLink(id, sourceNotificationId: ctx.sourceNotificationId);
}
