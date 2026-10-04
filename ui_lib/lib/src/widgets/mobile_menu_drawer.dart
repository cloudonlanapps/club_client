import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'bordered_menu_list.dart';

/// A reusable drawer that renders groups of [BorderedMenuList] items
/// separated by vertical spacing.
///
/// Each inner list in [menuItemGroups] becomes a separate [BorderedMenuList].
/// [footerItems], when given, form one more list pinned to the drawer's
/// bottom, apart from the groups; the groups scroll above it when the
/// drawer is short.
class MobileMenuDrawer extends StatelessWidget {
  const MobileMenuDrawer({
    required this.menuItemGroups,
    this.title = 'Menu',
    this.footerItems = const [],
    super.key,
  });

  final String title;
  final List<List<BorderedMenuItem>> menuItemGroups;

  /// Items set apart at the bottom of the drawer, e.g. a link out of the
  /// site; empty means no footer.
  final List<BorderedMenuItem> footerItems;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.h3),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final group in menuItemGroups) ...[
                        const SizedBox(height: 16),
                        BorderedMenuList(items: group),
                      ],
                    ],
                  ),
                ),
              ),
              if (footerItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                BorderedMenuList(items: footerItems),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
