import '../models/notification_filter.dart';

/// Human-readable label for [NotificationTypeFilter] values. Used in both
/// the filter dropdown's selected line and the option list.
String notificationTypeLabel(NotificationTypeFilter value) {
  switch (value) {
    case NotificationTypeFilter.all:
      return 'All';
    case NotificationTypeFilter.info:
      return 'Info';
    case NotificationTypeFilter.actionPending:
      return 'Action Pending';
    case NotificationTypeFilter.broadcast:
      return 'Broadcast';
  }
}
