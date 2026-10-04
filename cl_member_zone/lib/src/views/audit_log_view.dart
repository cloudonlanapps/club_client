import 'package:cl_remote_store/cl_remote_store.dart'
    show AuditLogScope, clAuditLogMasterProvider;
import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView, TitleRow;

/// Read-only audit-log view for a single [scope] (the global feed, or one
/// event / group / venue / user).
///
/// Renders the server-composed summary sentence per row, with a muted
/// local-time line. Long-pressing a row reveals the raw structured fields
/// (action code, actor / target, resource, and the details JSON) so the
/// default list stays clean. Manual pagination — Prev / Next, no infinite
/// scroll.
///
/// Gating is the screen's job; this view only asserts the precondition the
/// screen promised (global ⇒ super-admin, entity scope ⇒ admin).
class AuditLogView extends ConsumerStatefulWidget {
  const AuditLogView({
    required this.currentUser,
    required this.scope,
    required this.title,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final AuditLogScope scope;
  final String title;
  final VoidCallback? onBack;

  @override
  ConsumerState<AuditLogView> createState() => _AuditLogViewState();
}

class _AuditLogViewState extends ConsumerState<AuditLogView> {
  /// Ids of rows currently expanded to show their raw JSON.
  final Set<int> _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    assert(
      widget.scope.isGlobal
          ? widget.currentUser.isSuperAdmin
          : widget.currentUser.isAdmin,
      'AuditLogView reached without the required role for scope '
      '${widget.scope}. Screen gate failed.',
    );

    final theme = ShadTheme.of(context);
    final asyncPage = ref.watch(clAuditLogMasterProvider(widget.scope));
    final notifier = ref.read(clAuditLogMasterProvider(widget.scope).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(title: widget.title, onBack: widget.onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Activity history',
                  style: theme.textTheme.muted,
                ),
              ),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                leading: const Icon(Icons.refresh, size: 16),
                onPressed: notifier.refresh,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: asyncPage.when(
            loading: () => const LoadingView(message: 'Loading history…'),
            error: (e, _) => _ErrorState(onRetry: notifier.refresh),
            data: (page) => _PageBody(
              page: page,
              expanded: _expanded,
              onToggle: _toggle,
              onPrev: notifier.previousPage,
              onNext: notifier.nextPage,
            ),
          ),
        ),
      ],
    );
  }

  void _toggle(int id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.page,
    required this.expanded,
    required this.onToggle,
    required this.onPrev,
    required this.onNext,
  });

  final AuditLogPage page;
  final Set<int> expanded;
  final ValueChanged<int> onToggle;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (page.rows.isEmpty) {
      return Center(
        child: Text('No activity yet.', style: theme.textTheme.muted),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: page.rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final row = page.rows[i];
              return _AuditRowTile(
                row: row,
                expanded: expanded.contains(row.id),
                onLongPress: () => onToggle(row.id),
              );
            },
          ),
        ),
        _Pager(page: page, onPrev: onPrev, onNext: onNext),
      ],
    );
  }
}

class _AuditRowTile extends StatelessWidget {
  const _AuditRowTile({
    required this.row,
    required this.expanded,
    required this.onLongPress,
  });

  final AuditLogRow row;
  final bool expanded;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.summaryEn ?? row.action,
              style: theme.textTheme.p,
            ),
            const SizedBox(height: 4),
            Text(
              row.timestampUtc.toLocalDateTimeMedium(),
              style: theme.textTheme.muted,
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              _RawDetails(row: row),
            ],
          ],
        ),
      ),
    );
  }
}

/// Monochrome key/value block revealed on long-press.
class _RawDetails extends StatelessWidget {
  const _RawDetails({required this.row});

  final AuditLogRow row;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fields = <(String, String)>[
      ('Action', row.action),
      if (row.actor != null) ('Actor', _user(row.actor!)),
      if (row.target != null) ('Target', _user(row.target!)),
      if (row.resource != null) ('Resource', _resource(row.resource!)),
    ];
    final details = row.details;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in fields) _kv(theme, label, value),
          if (details != null && details.isNotEmpty) ...[
            _kv(theme, 'Details', ''),
            for (final entry in details.entries)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: _kv(theme, entry.key, '${entry.value}'),
              ),
          ],
        ],
      ),
    );
  }

  static String _user(AuditUserRef ref) {
    final name = ref.fullName;
    return (name != null && name.isNotEmpty)
        ? '$name (${ref.username})'
        : ref.username;
  }

  static String _resource(Map<String, dynamic> resource) {
    final type = resource['type'];
    if (type == 'occurrence') {
      final title = resource['eventTitle'] ?? 'event #${resource['eventId']}';
      final at = resource['occurrenceTimeUtc'];
      final when = at is int
          ? DateTime.fromMillisecondsSinceEpoch(
              at,
              isUtc: true,
            ).toLocalDateTimeMedium()
          : '$at';
      return 'occurrence of $title @ $when';
    }
    final id = resource['id'];
    final label = resource['label'];
    final base = '$type${id == null ? '' : ' #$id'}';
    return (label is String && label.isNotEmpty) ? '$base — $label' : base;
  }

  static Widget _kv(ShadThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.small,
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.onPrev,
    required this.onNext,
  });

  final AuditLogPage page;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final from = page.total == 0 ? 0 : page.offset + 1;
    final to = page.offset + page.rows.length;
    final hasPrev = page.offset > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$from–$to of ${page.total}', style: theme.textTheme.muted),
          Row(
            children: [
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: hasPrev ? onPrev : null,
                child: const Text('Prev'),
              ),
              const SizedBox(width: 8),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: page.hasMore ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Couldn't load history.",
            style: theme.textTheme.p,
          ),
          const SizedBox(height: 8),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
