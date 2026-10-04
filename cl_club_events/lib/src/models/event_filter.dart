import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:meta/meta.dart';

/// User-controlled filter selection emitted by `EventFilterPopover`.
///
/// Holds only the dimensions the popover edits: [visibility] and
/// [includePast]. List screens that own this value typically combine it
/// with screen-specific inputs (event type, search term, usernames) before
/// calling their list provider.
@immutable
class EventFilter {
  const EventFilter({this.visibility, this.includePast = true});

  final Visibility? visibility;
  final bool includePast;

  EventFilter copyWith({
    Visibility? Function()? visibility,
    bool? includePast,
  }) {
    return EventFilter(
      visibility: visibility != null ? visibility() : this.visibility,
      includePast: includePast ?? this.includePast,
    );
  }

  @override
  String toString() =>
      'EventFilter(visibility: $visibility, includePast: $includePast)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventFilter &&
        other.visibility == visibility &&
        other.includePast == includePast;
  }

  @override
  int get hashCode => visibility.hashCode ^ includePast.hashCode;
}
