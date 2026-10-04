import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Save / Discard for the club details form, with a save failure shown
/// above them.
class ClubIdentitySaveBar extends StatelessWidget {
  const ClubIdentitySaveBar({
    required this.dirty,
    required this.busy,
    required this.onSave,
    required this.onDiscard,
    this.error,
    super.key,
  });

  final bool dirty;
  final bool busy;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final problem = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        if (problem != null)
          Text(
            problem,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            ShadButton.outline(
              key: const ValueKey('clubIdentity.discard'),
              onPressed: dirty && !busy ? onDiscard : null,
              child: const Text('Discard'),
            ),
            ShadButton(
              key: const ValueKey('clubIdentity.save'),
              onPressed: dirty && !busy ? onSave : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
