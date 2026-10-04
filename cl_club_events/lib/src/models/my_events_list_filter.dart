import 'package:flutter/foundation.dart';

/// Immutable filter state for the My Events list.
@immutable
class MyEventsListFilter {
  const MyEventsListFilter({
    this.selectedUsernames = const {},
    this.searchTerm,
    this.includePast = false,
  });

  /// Usernames to include in the filter.
  final Set<String> selectedUsernames;

  /// Text search term applied to event title and description.
  final String? searchTerm;

  /// Whether to include past (ended) events.
  final bool includePast;

  MyEventsListFilter copyWith({
    Set<String>? selectedUsernames,
    String? Function()? searchTerm,
    bool? includePast,
  }) {
    return MyEventsListFilter(
      selectedUsernames: selectedUsernames ?? this.selectedUsernames,
      searchTerm: searchTerm != null ? searchTerm() : this.searchTerm,
      includePast: includePast ?? this.includePast,
    );
  }

  @override
  String toString() {
    return 'MyEventsListFilter(selectedUsernames: $selectedUsernames, '
        'searchTerm: $searchTerm, includePast: $includePast)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MyEventsListFilter &&
        setEquals(other.selectedUsernames, selectedUsernames) &&
        other.searchTerm == searchTerm &&
        other.includePast == includePast;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(selectedUsernames),
    searchTerm,
    includePast,
  );
}
