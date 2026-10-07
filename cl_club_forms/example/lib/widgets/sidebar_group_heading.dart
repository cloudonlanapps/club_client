import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/demo_sizes.dart';

/// The name of a family of forms, above its entries in the sidebar.
class SidebarGroupHeading extends StatelessWidget {
  /// Creates the heading.
  const SidebarGroupHeading({required this.title, super.key});

  /// The family's name.
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DemoSizes.pagePadding,
        DemoSizes.sidebarGroupTopInset,
        DemoSizes.pagePadding,
        DemoSizes.smallGap,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: DemoSizes.sidebarGroupFontSize,
          letterSpacing: DemoSizes.sidebarGroupLetterSpacing,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}
