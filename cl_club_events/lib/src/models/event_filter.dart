import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:meta/meta.dart';

/// User-controlled filter selection emitted by `EventFilterPopover`.
///
/// Holds only the dimensions the popover edits: [visibility],
/// [includePast] and [showArchived]. List screens that own this value
/// typically combine it with screen-specific inputs (event type, search
/// term, usernames) before calling their list provider.
@immutable
class EventFilter {
  const EventFilter({
    this.visibility,
    this.includePast = true,
    this.showArchived = false,
  });

  final Visibility? visibility;
  final bool includePast;

  /// Whether archived events are listed with the live ones (admin lists).
  final bool showArchived;

  EventFilter copyWith({
    Visibility? Function()? visibility,
    bool? includePast,
    bool? showArchived,
  }) {
    return EventFilter(
      visibility: visibility != null ? visibility() : this.visibility,
      includePast: includePast ?? this.includePast,
      showArchived: showArchived ?? this.showArchived,
    );
  }

  @override
  String toString() =>
      'EventFilter(visibility: $visibility, includePast: $includePast, '
      'showArchived: $showArchived)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventFilter &&
        other.visibility == visibility &&
        other.includePast == includePast &&
        other.showArchived == showArchived;
  }

  @override
  int get hashCode =>
      visibility.hashCode ^ includePast.hashCode ^ showArchived.hashCode;
}
