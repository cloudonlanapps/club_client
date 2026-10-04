import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionIcon, isMobileWidth;

/// Filter icon button that opens a popover with status and role selects.
///
/// Shows a badge with the count of active filters when any are applied.
class UserFilterPopover extends ConsumerStatefulWidget {
  const UserFilterPopover({
    required this.filter,
    required this.onFilterChanged,
    this.showStatusFilter = true,
    super.key,
  });

  final UserListFilter filter;
  final ValueChanged<UserListFilter> onFilterChanged;

  /// Whether to show the status filter. Set to false for coach users
  /// who only see active users.
  final bool showStatusFilter;

  @override
  ConsumerState<UserFilterPopover> createState() => UserFilterPopoverState();
}

class UserFilterPopoverState extends ConsumerState<UserFilterPopover> {
  final popoverController = ShadPopoverController();

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  int get activeFilterCount {
    var count = 0;
    if (widget.filter.status != null) count++;
    if (widget.filter.role != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final count = activeFilterCount;

    final statsAsync = ref.watch(clUserStatsProvider);
    final stats = statsAsync.valueOrNull ?? const ClUserStatsData();

    return ShadPopover(
      controller: popoverController,
      popover: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (count > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: () {
                      widget.onFilterChanged(
                        widget.filter.copyWith(
                          status: () => null,
                          role: () => null,
                        ),
                      );
                    },
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
              if (widget.showStatusFilter) ...[
                const SizedBox(height: 16),

                // Status select
                Text('Status', style: theme.textTheme.small),
                const SizedBox(height: 6),
                ShadSelect<String>(
                  placeholder: const Text('All statuses'),
                  initialValue: widget.filter.status?.name,
                  onChanged: (value) {
                    final status = value == null || value.isEmpty
                        ? null
                        : UserStatus.fromName(value);
                    widget.onFilterChanged(
                      widget.filter.copyWith(status: () => status),
                    );
                  },
                  options: [
                    ShadOption(
                      value: '',
                      child: Builder(
                        builder: (_) {
                          final n =
                              stats.total -
                              stats.pendingCount -
                              stats.registeredCount;
                          return Text('All ($n)');
                        },
                      ),
                    ),
                    for (final s in UserStatus.values)
                      if (s != UserStatus.registered && s != UserStatus.pending)
                        ShadOption(
                          value: s.name,
                          child: Text(
                            '${_capitalize(s.name)} '
                            '(${stats.countByStatus(s)})',
                          ),
                        ),
                    // Signed up but not submitted: never in the default
                    // list, fetched only when this option is shown (#91).
                    ShadOption(
                      value: UserStatus.registered.name,
                      child: const _RegisteredLabel(),
                    ),
                  ],
                  selectedOptionBuilder: (context, value) {
                    if (value.isEmpty) return const Text('All');
                    final s = UserStatus.fromName(value);
                    if (s == UserStatus.registered) {
                      return const _RegisteredLabel();
                    }
                    return Text(
                      '${_capitalize(s.name)} (${stats.countByStatus(s)})',
                    );
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Role select
              Text('Role', style: theme.textTheme.small),
              const SizedBox(height: 6),
              ShadSelect<String>(
                placeholder: const Text('All roles'),
                initialValue: widget.filter.role,
                onChanged: (value) {
                  widget.onFilterChanged(
                    widget.filter.copyWith(
                      role: () => value == null || value.isEmpty ? null : value,
                    ),
                  );
                },
                options: [
                  const ShadOption(value: '', child: Text('All')),
                  for (final r in Role.values)
                    ShadOption(
                      value: r.name,
                      child: Text(_capitalize(r.name)),
                    ),
                ],
                selectedOptionBuilder: (context, value) {
                  if (value.isEmpty) return const Text('All');
                  return Text(_capitalize(value));
                },
              ),
            ],
          ),
        ),
      ),
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        offset: const Offset(12, -6),
        child: isMobileWidth(context)
            ? ActionIcon(
                icon: Icons.filter_list,
                onPressed: popoverController.toggle,
              )
            : ActionButton(
                label: 'Filter',
                onPressed: popoverController.toggle,
              ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// "Registered, not submitted (n)", counting users who signed up but have
/// not submitted for review.
class _RegisteredLabel extends ConsumerWidget {
  const _RegisteredLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(clRegisteredUsersProvider).valueOrNull?.length;
    return Text('Registered, not submitted${n == null ? '' : ' ($n)'}');
  }
}
