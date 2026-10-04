import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Canonical edit ("pencil") affordance for an editable section header.
///
/// Shadcn-only by design: built on [GestureDetector] (no Material ink / no
/// `InkWell`, and no tooltip overlay — see issue 473). Callers render it only
/// when the viewer has permission to edit the section; it carries no
/// permission logic of its own.
class SectionEditButton extends StatelessWidget {
  const SectionEditButton({required this.onTap, super.key});

  /// Invoked when the affordance is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            LucideIcons.pencil,
            size: 14,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
