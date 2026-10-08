import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'my_events_switch.dart';

/// Title of the Events section of a profile, with its two switches
/// (club_client#88): one adds the cancelled events to the list, one the past
/// ones. A null callback leaves that switch out.
class MyEventsSectionHeader extends StatelessWidget {
  const MyEventsSectionHeader({
    required this.showCancelled,
    required this.showPast,
    required this.onShowCancelledChanged,
    required this.onShowPastChanged,
    super.key,
  });

  /// Title of the section.
  static const String title = 'Events';

  /// Label of the switch that adds the cancelled events.
  static const String cancelledSwitchLabel = 'Cancelled events';

  /// Label of the switch that adds the events that are over.
  static const String pastSwitchLabel = 'Past events';

  final bool showCancelled;
  final bool showPast;
  final ValueChanged<bool>? onShowCancelledChanged;
  final ValueChanged<bool>? onShowPastChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(title, style: theme.textTheme.h4),
        if (onShowCancelledChanged != null || onShowPastChanged != null)
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              if (onShowCancelledChanged != null)
                MyEventsSwitch(
                  label: cancelledSwitchLabel,
                  value: showCancelled,
                  onChanged: onShowCancelledChanged!,
                ),
              if (onShowPastChanged != null)
                MyEventsSwitch(
                  label: pastSwitchLabel,
                  value: showPast,
                  onChanged: onShowPastChanged!,
                ),
            ],
          ),
      ],
    );
  }
}
