import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One labelled switch of the Events section of a profile (club_client#88).
class MyEventsSwitch extends StatelessWidget {
  const MyEventsSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        ShadSwitch(value: value, onChanged: onChanged),
        Text(label, style: theme.textTheme.small),
      ],
    );
  }
}
