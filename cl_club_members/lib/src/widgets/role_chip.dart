import 'package:cl_club_members/src/widgets/role_chips.dart' show RoleChips;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Toggle chip for a single [Role]. Used by [RoleChips].
class RoleChip extends StatelessWidget {
  const RoleChip({
    required this.role,
    required this.selected,
    required this.onToggle,
    this.enabled = true,
    super.key,
  });

  final Role role;
  final bool selected;
  final bool enabled;
  final void Function({required bool selected}) onToggle;

  String get _label {
    final n = role.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return ShadButton.secondary(
        size: ShadButtonSize.sm,
        onPressed: enabled ? () => onToggle(selected: false) : null,
        child: Text(_label),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: enabled ? () => onToggle(selected: true) : null,
      child: Text(_label),
    );
  }
}
