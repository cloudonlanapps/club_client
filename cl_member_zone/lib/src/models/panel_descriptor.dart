import 'package:flutter/widgets.dart';

import 'dashboard_panel_id.dart';
import 'panel_role.dart';

/// Static description of a dashboard panel.
///
/// Built once into a registry table; never serialised, never copied.
@immutable
class PanelDescriptor {
  const PanelDescriptor({
    required this.id,
    required this.title,
    required this.icon,
    required this.requiredRole,
    required this.builder,
  });

  final DashboardPanelId id;
  final String title;
  final IconData icon;
  final PanelRole requiredRole;
  final WidgetBuilder builder;

  @override
  String toString() =>
      'PanelDescriptor(id: $id, title: $title, '
      'requiredRole: $requiredRole)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PanelDescriptor &&
        other.id == id &&
        other.title == title &&
        other.icon == icon &&
        other.requiredRole == requiredRole &&
        other.builder == builder;
  }

  @override
  int get hashCode => Object.hash(id, title, icon, requiredRole, builder);
}
