import 'package:meta/meta.dart';

import 'dashboard_panel_id.dart';

/// Persisted dashboard preferences for a single user.
///
/// `selected` is the set of panels currently on the dashboard (in fixed
/// display order). `expandedOnMobile` is the subset of those panels that
/// start expanded in the mobile accordion.
@immutable
class DashboardPrefs {
  const DashboardPrefs({
    required this.selected,
    required this.expandedOnMobile,
  });

  final Set<DashboardPanelId> selected;
  final Set<DashboardPanelId> expandedOnMobile;

  DashboardPrefs copyWith({
    Set<DashboardPanelId>? selected,
    Set<DashboardPanelId>? expandedOnMobile,
  }) => DashboardPrefs(
    selected: selected ?? this.selected,
    expandedOnMobile: expandedOnMobile ?? this.expandedOnMobile,
  );

  @override
  String toString() =>
      'DashboardPrefs(selected: $selected, '
      'expandedOnMobile: $expandedOnMobile)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DashboardPrefs) return false;
    if (other.selected.length != selected.length) return false;
    if (other.expandedOnMobile.length != expandedOnMobile.length) return false;
    for (final id in selected) {
      if (!other.selected.contains(id)) return false;
    }
    for (final id in expandedOnMobile) {
      if (!other.expandedOnMobile.contains(id)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(selected),
    Object.hashAllUnordered(expandedOnMobile),
  );
}
