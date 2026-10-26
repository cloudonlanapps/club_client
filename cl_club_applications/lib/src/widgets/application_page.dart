import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_sizes.dart';

/// The scrolling, centred column every Applications page lays out in, its
/// [heading] first with [trailing] beside it.
class ApplicationPage extends StatelessWidget {
  const ApplicationPage({
    required this.children,
    this.heading,
    this.trailing,
    super.key,
  });

  /// The page's heading; none when the host shows its own title row.
  final String? heading;

  /// Beside the heading: the page's main action.
  final Widget? trailing;

  /// The page's sections, under the heading.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(ApplicationViewSizes.pagePadding),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ApplicationViewSizes.maxContentWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ApplicationViewSizes.sectionGap,
          children: [
            if (heading case final String heading)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      heading,
                      style: ShadTheme.of(context).textTheme.h3,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ...children,
          ],
        ),
      ),
    ),
  );
}
