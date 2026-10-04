import 'package:flutter/foundation.dart';

/// Whether the notifications list shows everything or only unread rows.
enum NotificationReadFilter { all, unread }

/// Coarse, action-oriented buckets derived from fields already present on
/// `AppNotification`. The buckets are mutually exclusive and exhaustive:
///
/// - [info]: FYI rows (`pendingActionType == null && broadcastId == null`).
/// - [actionPending]: rows requiring user action (`pendingActionType != null`).
/// - [broadcast]: rows fanned out from a broadcast (`broadcastId != null`).
///
/// `all` is the wildcard that matches every row.
enum NotificationTypeFilter {
  all,
  info,
  actionPending,
  broadcast,
}

/// Combined filter state for the full Notification screen. Used as the
/// value of a `NotifierProvider`; applied client-side over the loaded
/// `clNotificationsMasterProvider` map.
@immutable
class NotificationFilter {
  const NotificationFilter({
    this.read = NotificationReadFilter.all,
    this.type = NotificationTypeFilter.all,
  });

  final NotificationReadFilter read;
  final NotificationTypeFilter type;

  NotificationFilter copyWith({
    NotificationReadFilter? read,
    NotificationTypeFilter? type,
  }) {
    return NotificationFilter(
      read: read ?? this.read,
      type: type ?? this.type,
    );
  }

  @override
  String toString() => 'NotificationFilter(read: $read, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationFilter &&
        other.read == read &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(read, type);
}
