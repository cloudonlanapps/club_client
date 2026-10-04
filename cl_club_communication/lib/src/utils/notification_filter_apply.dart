import 'package:club_sdk_2/club_sdk_2.dart';

import '../models/notification_filter.dart';

/// Apply [filter] to [notifications] and return the result sorted by
/// `createdAtUtc`, newest first.
///
/// Pure function — no side effects, no provider reads. Hosted in `utils/`
/// because both the screen and its widget tests rely on the same logic.
List<AppNotification> applyNotificationFilter(
  Map<int, AppNotification> notifications,
  NotificationFilter filter,
) {
  final result = <AppNotification>[];
  for (final n in notifications.values) {
    if (!_matchesRead(n, filter.read)) continue;
    if (!_matchesType(n, filter.type)) continue;
    result.add(n);
  }
  result.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
  return result;
}

/// True if [n] belongs to the bucket that [type] represents. `all` matches
/// every notification.
bool matchesNotificationType(AppNotification n, NotificationTypeFilter type) =>
    _matchesType(n, type);

bool _matchesRead(AppNotification n, NotificationReadFilter read) {
  switch (read) {
    case NotificationReadFilter.all:
      return true;
    case NotificationReadFilter.unread:
      return !n.isRead;
  }
}

bool _matchesType(AppNotification n, NotificationTypeFilter type) {
  switch (type) {
    case NotificationTypeFilter.all:
      return true;
    case NotificationTypeFilter.broadcast:
      return n.broadcastId != null;
    case NotificationTypeFilter.actionPending:
      return n.pendingActionType != null;
    case NotificationTypeFilter.info:
      return n.pendingActionType == null && n.broadcastId == null;
  }
}
