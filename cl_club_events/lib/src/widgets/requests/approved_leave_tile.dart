import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One member on approved leave for the session, with the reason they gave;
/// read-only (club_client#437).
class ApprovedLeaveTile extends StatelessWidget {
  const ApprovedLeaveTile({
    required this.displayName,
    this.leaveReason,
    super.key,
  });

  final String displayName;
  final String? leaveReason;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final reason = leaveReason?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayName, style: theme.textTheme.small),
          Text('On leave', style: theme.textTheme.muted),
          if (reason.isNotEmpty) Text(reason, style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
