import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/demo_keys.dart';
import '../data/form_demo_entries.dart';
import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'sidebar_group_heading.dart';
import 'sidebar_header.dart';
import 'sidebar_item.dart';

/// The list of every form, family by family.
class FormsSidebar extends StatelessWidget {
  /// Creates the sidebar.
  const FormsSidebar({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  /// The entry being shown.
  final FormDemoEntry selected;

  /// Called with the entry that was tapped.
  final ValueChanged<FormDemoEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(right: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SidebarHeader(),
            Expanded(
              child: ListView(
                children: [
                  for (final group in FormDemoGroup.values) ...[
                    SidebarGroupHeading(title: group.title),
                    for (final entry in FormDemoEntries.of(group))
                      SidebarItem(
                        key: DemoKeys.sidebarItem(entry.id),
                        title: entry.title,
                        selected: entry.id == selected.id,
                        onTap: () => onSelect(entry),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
