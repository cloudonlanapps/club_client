import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionIcon, isMobileWidth;

import '../models/event_filter.dart';

/// Filter icon button + popover for event lists.
///
/// Self-contained: holds the in-progress [EventFilter] internally and emits
/// changes through [onChanged]. Place one instance per list view; instances
/// do not share state.
///
/// Set [filterByVisibility] to `true` to expose the visibility selector
/// (admin / coach contexts). When `false`, only the include-past switch
/// is shown.
class EventFilterPopover extends StatefulWidget {
  const EventFilterPopover({
    required this.initial,
    required this.onChanged,
    this.filterByVisibility = false,
    super.key,
  });

  final EventFilter initial;
  final bool filterByVisibility;
  final ValueChanged<EventFilter> onChanged;

  @override
  State<EventFilterPopover> createState() => EventFilterPopoverState();
}

class EventFilterPopoverState extends State<EventFilterPopover> {
  final popoverController = ShadPopoverController();
  late EventFilter filter = widget.initial;

  @override
  void didUpdateWidget(covariant EventFilterPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != oldWidget.initial && widget.initial != filter) {
      filter = widget.initial;
    }
  }

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  void update(EventFilter next) {
    setState(() => filter = next);
    widget.onChanged(next);
  }

  int get activeFilterCount {
    var count = 0;
    if (widget.filterByVisibility && filter.visibility != null) count++;
    if (!filter.includePast) count++;
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
                    onPressed: () => update(const EventFilter()),
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (widget.filterByVisibility) ...[
                Text('Visibility', style: theme.textTheme.small),
                const SizedBox(height: 6),
                ShadSelect<String>(
                  placeholder: const Text('All'),
                  initialValue: filter.visibility?.name,
                  onChanged: (value) {
                    final visibility = value == null || value.isEmpty
                        ? null
                        : Visibility.values.byName(value);
                    update(filter.copyWith(visibility: () => visibility));
                  },
                  options: [
                    const ShadOption(value: '', child: Text('All')),
                    for (final v in Visibility.values)
                      ShadOption(
                        value: v.name,
                        child: Text(capitalize(v.name)),
                      ),
                  ],
                  selectedOptionBuilder: (context, value) {
                    if (value.isEmpty) return const Text('All');
                    return Text(capitalize(value));
                  },
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Include past', style: theme.textTheme.small),
                  ShadSwitch(
                    value: filter.includePast,
                    onChanged: (value) =>
                        update(filter.copyWith(includePast: value)),
                  ),
                ],
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

  static String capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
