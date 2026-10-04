import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';

@immutable
class GroupAdminAction {
  const GroupAdminAction({
    required this.key,
    required this.label,
    this.destructive = false,
  });

  final String key;
  final String label;
  final bool destructive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupAdminAction &&
          other.key == key &&
          other.label == label &&
          other.destructive == destructive;

  @override
  int get hashCode => key.hashCode ^ label.hashCode ^ destructive.hashCode;

  @override
  String toString() =>
      'GroupAdminAction(key: $key, label: $label, destructive: $destructive)';
}

List<GroupAdminAction> groupAdminActionsFor(
  Group group, {
  required bool isSuperAdmin,
}) {
  if (!group.isActive) {
    return [
      const GroupAdminAction(key: 'restore', label: 'Restore'),
      if (isSuperAdmin)
        const GroupAdminAction(
          key: 'hardDelete',
          label: 'Hard Delete',
          destructive: true,
        ),
    ];
  }
  return const [
    GroupAdminAction(key: 'rename', label: 'Rename'),
    GroupAdminAction(key: 'delete', label: 'Delete', destructive: true),
  ];
}
