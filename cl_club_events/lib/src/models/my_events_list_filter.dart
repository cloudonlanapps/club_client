import 'package:flutter/foundation.dart';

/// Immutable filter state for the My Events list.
@immutable
class MyEventsListFilter {
  const MyEventsListFilter({
    required this.username,
    this.searchTerm,
    this.includePast = false,
  });

  /// The member whose events are listed.
  final String username;

  /// Text search term applied to event title and description.
  final String? searchTerm;

  /// Whether to include past (ended) events.
  final bool includePast;

  MyEventsListFilter copyWith({
    String? username,
    String? Function()? searchTerm,
    bool? includePast,
  }) {
    return MyEventsListFilter(
      username: username ?? this.username,
      searchTerm: searchTerm != null ? searchTerm() : this.searchTerm,
      includePast: includePast ?? this.includePast,
    );
  }

  @override
  String toString() {
    return 'MyEventsListFilter(username: $username, '
        'searchTerm: $searchTerm, includePast: $includePast)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MyEventsListFilter &&
        other.username == username &&
        other.searchTerm == searchTerm &&
        other.includePast == includePast;
  }

  @override
  int get hashCode => Object.hash(username, searchTerm, includePast);
}
