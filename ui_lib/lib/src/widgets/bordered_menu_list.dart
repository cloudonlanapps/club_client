import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A single item in a [BorderedMenuList].
class BorderedMenuItem {
  const BorderedMenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// A grouped list of menu items displayed in a bordered, rounded container
/// with dividers between items and trailing chevron icons.
///
/// Optionally shows a [title] above the list as a section header.
class BorderedMenuList extends StatelessWidget {
  const BorderedMenuList({required this.items, this.title, super.key});

  final String? title;
  final List<BorderedMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title!,
              style: theme.textTheme.large.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.ring, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.ring,
                  ),
                InkWell(
                  onTap: items[i].onTap,
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(12) : Radius.zero,
                    bottom: i == items.length - 1
                        ? const Radius.circular(12)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[i].label,
                            style: theme.textTheme.large,
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
