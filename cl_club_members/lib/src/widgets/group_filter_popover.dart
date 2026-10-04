import 'package:cl_club_members/src/models/group_list_filter.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionIcon, isMobileWidth;

/// Filter popover for the group list — type filter and deleted toggle.
class GroupFilterPopover extends StatefulWidget {
  const GroupFilterPopover({
    required this.filter,
    required this.onFilterChanged,
    this.showDeletedToggle = true,
    super.key,
  });

  final GroupListFilter filter;
  final ValueChanged<GroupListFilter> onFilterChanged;
  final bool showDeletedToggle;

  @override
  State<GroupFilterPopover> createState() => GroupFilterPopoverState();
}

class GroupFilterPopoverState extends State<GroupFilterPopover> {
  final popoverController = ShadPopoverController();

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  int get activeFilterCount {
    var count = 0;
    if (widget.filter.typeFilter != GroupTypeFilter.all) count++;
    if (widget.filter.showDeleted) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final count = activeFilterCount;

    return ShadPopover(
      controller: popoverController,
      popover: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 220,
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
                      widget.onFilterChanged(const GroupListFilter());
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

              // Type filter
              const SizedBox(height: 8),
              Text('Type', style: theme.textTheme.small),
              const SizedBox(height: 6),
              ShadSelect<GroupTypeFilter>(
                placeholder: const Text('All types'),
                initialValue: widget.filter.typeFilter,
                onChanged: (value) {
                  widget.onFilterChanged(
                    widget.filter.copyWith(
                      typeFilter: value ?? GroupTypeFilter.all,
                    ),
                  );
                },
                options: const [
                  ShadOption(value: GroupTypeFilter.all, child: Text('All')),
                  ShadOption(
                    value: GroupTypeFilter.manual,
                    child: Text('Manual'),
                  ),
                  ShadOption(value: GroupTypeFilter.auto, child: Text('Auto')),
                  ShadOption(
                    value: GroupTypeFilter.semiAuto,
                    child: Text('Semi-auto'),
                  ),
                ],
                selectedOptionBuilder: (context, value) {
                  switch (value) {
                    case GroupTypeFilter.all:
                      return const Text('All');
                    case GroupTypeFilter.manual:
                      return const Text('Manual');
                    case GroupTypeFilter.auto:
                      return const Text('Auto');
                    case GroupTypeFilter.semiAuto:
                      return const Text('Semi-auto');
                  }
                },
              ),

              // Deleted toggle
              if (widget.showDeletedToggle) ...[
                const SizedBox(height: 16),
                ShadSwitchFormField(
                  id: 'showDeleted',
                  initialValue: widget.filter.showDeleted,
                  label: const Text('Show deleted'),
                  onChanged: (value) {
                    widget.onFilterChanged(
                      widget.filter.copyWith(showDeleted: value),
                    );
                  },
                ),
              ],
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
}
