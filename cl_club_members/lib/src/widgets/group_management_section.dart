import 'package:cl_club_forms/cl_club_forms.dart' show TwoColumnGrid;
import 'package:cl_club_members/src/utils/admin_group_actions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

class GroupManagementSection extends StatelessWidget {
  const GroupManagementSection({
    required this.group,
    required this.isSuperAdmin,
    this.onStatusAction,
    super.key,
  });

  final Group group;
  final bool isSuperAdmin;
  final ValueChanged<String>? onStatusAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final actions = onStatusAction != null
        ? groupAdminActionsFor(group, isSuperAdmin: isSuperAdmin)
        : const <GroupAdminAction>[];
    final buttons = <Widget>[
      for (final action in actions)
        ActionButton(
          label: action.label,
          onPressed: () => onStatusAction!(action.key),
        ),
    ];
    while (buttons.length < 4) {
      buttons.add(
        const IgnorePointer(
          child: Opacity(
            opacity: 0,
            child: ActionButton(label: ''),
          ),
        ),
      );
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group Management', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          TwoColumnGrid(
            spacing: 8,
            runSpacing: 8,
            singleColumnBreakpoint: 0,
            children: buttons,
          ),
        ],
      ),
    );
  }
}
