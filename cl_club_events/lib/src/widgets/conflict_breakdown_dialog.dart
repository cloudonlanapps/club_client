import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shows a per-user conflict breakdown for a camp enrolment pre-flight.
///
/// Returns `true` if the operator chooses to proceed despite the
/// conflicts, `false` (or `null`) if they cancel. Camps are flag-don't-
/// block, so the caller is expected to honour `true` by continuing with
/// the assign/invite mutation.
Future<bool?> showConflictBreakdownDialog(
  BuildContext context, {
  required UserConflictReport report,
  required String title,
  String? Function(String username)? displayNameResolver,
}) async {
  return showShadDialog<bool>(
    context: context,
    builder: (context) => ConflictBreakdownDialog(
      report: report,
      title: title,
      displayNameResolver: displayNameResolver,
    ),
  );
}

class ConflictBreakdownDialog extends StatelessWidget {
  const ConflictBreakdownDialog({
    required this.report,
    required this.title,
    this.displayNameResolver,
    super.key,
  });

  final UserConflictReport report;
  final String title;
  final String? Function(String username)? displayNameResolver;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final conflicts = report.userConflicts;

    return ShadDialog(
      title: Text(title),
      description: Text(
        '${conflicts.length} selected user${conflicts.length == 1 ? '' : 's'} '
        'already have overlapping occurrences. You can still proceed; '
        'this is informational.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Proceed anyway'),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in conflicts) ...[
                ConflictUserPanel(
                  item: item,
                  displayName: displayNameResolver?.call(item.username),
                  theme: theme,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ConflictUserPanel extends StatelessWidget {
  const ConflictUserPanel({
    required this.item,
    required this.displayName,
    required this.theme,
    super.key,
  });

  final UserConflictItem item;
  final String? displayName;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = (displayName != null && displayName!.trim().isNotEmpty)
        ? '$displayName (${item.username})'
        : item.username;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.p),
          const SizedBox(height: 8),
          for (final event in item.events) ...[
            ConflictEventRow(event: event, theme: theme),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class ConflictEventRow extends StatelessWidget {
  const ConflictEventRow({
    required this.event,
    required this.theme,
    super.key,
  });

  final EventConflictItem event;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${event.eventTitle} · ${event.eventType}',
          style: theme.textTheme.small,
        ),
        for (final pair in event.occurrences)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '• ${_fmt(pair.targetStartUtc)} – '
              '${_fmt(pair.targetEndUtc)} overlaps '
              '${_fmt(pair.otherStartUtc)} – ${_fmt(pair.otherEndUtc)}',
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _fmt(DateTime utc) {
    final local = utc.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
