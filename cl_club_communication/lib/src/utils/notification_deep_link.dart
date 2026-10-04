import 'notification_registry.dart';

export 'notification_registry.dart'
    show
        NotifAdminUserLink,
        NotifAdminUserReviewLink,
        NotifCreditLink,
        NotifEvaluationLink,
        NotifEventLink,
        NotifGroupLink,
        NotifInquiriesLink,
        NotifMyEventLink,
        NotifMyEventsHomeLink,
        NotifMyGroupsLink,
        NotifMyReviewLink,
        NotifMyReviewsLink,
        NotifOccurrenceLink,
        NotifSelfProfileLink,
        NotifVenueLink,
        NotificationDeepLink,
        NotificationLinkContext,
        NotificationLinkResolver,
        resolveDeepLink;

/// Per-type deep-link resolver lookup, derived from [kNotificationKinds].
///
/// Preserved for tests and other call sites that walked the map directly;
/// new code should reach for [kNotificationKinds] / [kNotificationKindByType]
/// in `notification_registry.dart`. Rows whose registry entry has a `null`
/// [NotificationKind.deepLink] are intentionally absent from this map (same
/// behaviour as before — `resolveDeepLink` returns null for them).
final Map<String, NotificationLinkResolver> kNotificationLinks = {
  for (final k in kNotificationKinds)
    if (k.deepLink != null) k.type: k.deepLink!,
};
