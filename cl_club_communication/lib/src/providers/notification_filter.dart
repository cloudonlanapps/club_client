import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_filter.dart';

/// UI-layer state for the full Notification screen's filter controls.
///
/// Lives in `cl_member_zone` because the master notifications store in
/// `cl_remote_store` shouldn't carry view-only filter state (per the
/// centralized resource state management pattern in CLAUDE.md). The screen
/// watches this provider, derives the visible list, and passes setters
/// down to its filter controls.
final NotifierProvider<NotificationFilterNotifier, NotificationFilter>
notificationFilterProvider =
    NotifierProvider<NotificationFilterNotifier, NotificationFilter>(
      NotificationFilterNotifier.new,
    );

class NotificationFilterNotifier extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() => const NotificationFilter();

  void setRead(NotificationReadFilter read) {
    state = state.copyWith(read: read);
  }

  void setType(NotificationTypeFilter type) {
    state = state.copyWith(type: type);
  }
}
