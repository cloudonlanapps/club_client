/// Notifications and pending-actions widgets, providers, and views for
/// the club app.
///
/// Houses the cross-feature notification subsystem so other feature
/// packages (events, members, venues, member zone shell) can render
/// notification surfaces without depending on each other.
library;

// Providers
export 'src/providers/unified_notifications.dart'
    show UnifiedNotifications, unifiedNotificationsProvider;
// Public deep-link types and resolver
export 'src/utils/notification_registry.dart'
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
        resolveDeepLink;
export 'src/utils/notification_writes.dart'
    show markAllReadReporting, markReadThenOpen, showWriteFailure;
// Views (no Scaffold — host wraps them in their shell)
export 'src/views/notifications_list_view.dart' show NotificationsListView;
export 'src/views/pending_actions_list_view.dart' show PendingActionsListView;
// Widgets used by other packages' dashboard panels
export 'src/widgets/notification_row.dart' show NotificationRow;
