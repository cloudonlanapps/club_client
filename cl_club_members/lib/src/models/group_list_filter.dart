import 'package:meta/meta.dart';

/// Kind filter for the admin group list.
enum GroupTypeFilter {
  all,
  manual,
  auto,
  semiAuto,
}

/// Immutable filter state for the admin group list.
@immutable
class GroupListFilter {
  const GroupListFilter({
    this.searchTerm,
    this.showDeleted = false,
    this.typeFilter = GroupTypeFilter.all,
  });

  final String? searchTerm;
  final bool showDeleted;
  final GroupTypeFilter typeFilter;

  GroupListFilter copyWith({
    String? Function()? searchTerm,
    bool? showDeleted,
    GroupTypeFilter? typeFilter,
  }) {
    return GroupListFilter(
      searchTerm: searchTerm != null ? searchTerm() : this.searchTerm,
      showDeleted: showDeleted ?? this.showDeleted,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }

  @override
  String toString() {
    return 'GroupListFilter(searchTerm: $searchTerm, '
        'showDeleted: $showDeleted, typeFilter: $typeFilter)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupListFilter &&
        other.searchTerm == searchTerm &&
        other.showDeleted == showDeleted &&
        other.typeFilter == typeFilter;
  }

  @override
  int get hashCode =>
      searchTerm.hashCode ^ showDeleted.hashCode ^ typeFilter.hashCode;
}
