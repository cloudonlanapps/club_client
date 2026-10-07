import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/demo_sizes.dart';
import '../constants/demo_strings.dart';

/// The top of the sidebar: the app's name.
class SidebarHeader extends StatelessWidget {
  /// Creates the header.
  const SidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(DemoSizes.pagePadding),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: DemoSizes.smallGap,
        children: [
          Text(DemoStrings.appName, style: theme.textTheme.large),
          Text(DemoStrings.sidebarSubtitle, style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
