import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/demo_sizes.dart';

/// The bar above the main view on a wide window: the chosen form's name and
/// the demo's own controls.
class FormsTopBar extends StatelessWidget {
  /// Creates the bar.
  const FormsTopBar({required this.title, required this.trailing, super.key});

  /// The chosen form's name.
  final String title;

  /// Shown at the end of the bar.
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      height: DemoSizes.topBarHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: DemoSizes.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.large,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
