import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Read-only group audit info: created date and status.
///
/// Eligibility / kind is rendered in prose by the eligibility section; this
/// card carries only the boring audit fields a viewer might still want to
/// glance at.
class GroupInfoSection extends StatelessWidget {
  const GroupInfoSection({required this.group, super.key});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group Info', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          ReadOnlyField(
            label: 'Created',
            value: group.createdAtUtc.toLocalDateMedium(),
          ),
          const SizedBox(height: 8),
          ReadOnlyField(
            label: 'Status',
            value: group.isActive ? 'Active' : 'Deleted',
          ),
        ],
      ),
    );
  }
}
