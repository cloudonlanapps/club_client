import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Save / Discard for the website media draft, with a save failure that
/// belongs to no one slot shown above them.
class SiteMediaSaveBar extends StatelessWidget {
  const SiteMediaSaveBar({
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
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
                onPressed: dirty && !busy ? onDiscard : null,
                child: const Text('Discard'),
              ),
              ShadButton(
                key: const ValueKey('siteMedia.save'),
                onPressed: dirty && !busy ? onSave : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
