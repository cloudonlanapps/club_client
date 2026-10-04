import 'notification_registry.dart';

export 'notification_registry.dart'
    show
        NotificationDisplay,
        NotificationFormatterFn,
        formatNotification,
        kKnownUnimplementedTypes;

/// Per-type formatter lookup, derived from [kNotificationKinds].
///
/// Preserved for tests and other call sites that walked the map directly;
/// new code should reach for [kNotificationKinds] / [kNotificationKindByType]
/// in `notification_registry.dart`.
final Map<String, NotificationFormatterFn> kNotificationFormatters = {
  for (final k in kNotificationKinds) k.type: k.format,
};
