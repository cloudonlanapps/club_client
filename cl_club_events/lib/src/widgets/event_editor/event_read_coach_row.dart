import 'package:flutter/material.dart' hide Visibility;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PickerUser;

/// A tappable coach row in read mode: bullet + name, routing to the member on
/// tap when a handler is supplied.
class EventReadCoachRow extends StatelessWidget {
  const EventReadCoachRow({required this.coach, this.onTap, super.key});

  final PickerUser coach;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final row = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('• ${coach.displayName}', style: theme.textTheme.p),
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: row),
    );
  }
}
