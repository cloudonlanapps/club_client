import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:meta/meta.dart';

/// Immutable filter state for the event list.
@immutable
class EventListFilter {
  const EventListFilter({
    this.eventType,
    this.visibility,
    this.searchTerm,
    this.includePast = false,
    this.showArchived = false,
  });

  final EventType? eventType;
  final Visibility? visibility;
  final String? searchTerm;
  final bool includePast;

  /// Whether archived (soft-deleted) events are listed with the live ones.
  final bool showArchived;

  EventListFilter copyWith({
    EventType? Function()? eventType,
    Visibility? Function()? visibility,
    String? Function()? searchTerm,
    bool? includePast,
    bool? showArchived,
  }) {
    return EventListFilter(
      eventType: eventType != null ? eventType() : this.eventType,
      visibility: visibility != null ? visibility() : this.visibility,
      searchTerm: searchTerm != null ? searchTerm() : this.searchTerm,
      includePast: includePast ?? this.includePast,
      showArchived: showArchived ?? this.showArchived,
    );
  }

  @override
  String toString() {
    return 'EventListFilter(eventType: $eventType, visibility: $visibility, '
        'searchTerm: $searchTerm, includePast: $includePast, '
        'showArchived: $showArchived)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventListFilter &&
        other.eventType == eventType &&
        other.visibility == visibility &&
        other.searchTerm == searchTerm &&
        other.includePast == includePast &&
        other.showArchived == showArchived;
  }

  @override
  int get hashCode =>
      eventType.hashCode ^
      visibility.hashCode ^
      searchTerm.hashCode ^
      includePast.hashCode ^
      showArchived.hashCode;
}
