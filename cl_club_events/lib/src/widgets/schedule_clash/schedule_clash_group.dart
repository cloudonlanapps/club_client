import 'package:club_sdk_2/club_sdk_2.dart' show EventConflictItem;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/schedule_clash_gate.dart';
import 'schedule_clash_item.dart';

/// The clashes of one gate in the schedule clash dialog: the gate's heading
/// (venue, organizer or coach) over each clashing event.
class ScheduleClashGroup extends StatelessWidget {
  /// Lists [items], the clashes the report gives for [gate].
  const ScheduleClashGroup({
    required this.gate,
    required this.items,
    super.key,
  });

  /// The gate these clashes were found by.
  final ScheduleClashGate gate;

  /// The clashing events, in the report's order.
  final List<EventConflictItem> items;

  /// The space between the heading and each clashing event.
  static const double itemSpacing = 8;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(gate.label, style: theme.textTheme.small),
        for (final item in items) ...[
          const SizedBox(height: itemSpacing),
          ScheduleClashItem(item: item),
        ],
      ],
    );
  }
}
