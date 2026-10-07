import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/demo_sizes.dart';

/// One entry of the sidebar.
class SidebarItem extends StatelessWidget {
  /// Creates the item.
  const SidebarItem({
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// The entry's name.
  final String title;

  /// Whether this entry is the one being shown.
  final bool selected;

  /// Called when the item is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final radius = BorderRadius.circular(DemoSizes.radius);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DemoSizes.sidebarItemInset,
      ),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(
                alpha: DemoSizes.selectedAlpha,
              )
            : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DemoSizes.sidebarItemInset,
              vertical: DemoSizes.sidebarItemVerticalInset,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: DemoSizes.sidebarItemFontSize,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
