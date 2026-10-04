import 'package:flutter/widgets.dart';

/// Navigation item definition.
class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.path,
    this.section,
    this.adminOnly = false,
    this.superAdminOnly = false,
    this.coachOrAdmin = false,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final String path;
  final String? section;
  final bool adminOnly;

  /// Shown to super-admins only.
  final bool superAdminOnly;
  final bool coachOrAdmin;
  final int? badgeCount;

  bool isVisibleFor({
    required bool isAdmin,
    required bool isCoach,
    bool isSuperAdmin = false,
  }) {
    if (superAdminOnly) return isSuperAdmin;
    if (adminOnly) return isAdmin;
    if (coachOrAdmin) return isAdmin || isCoach;
    return true;
  }
}
