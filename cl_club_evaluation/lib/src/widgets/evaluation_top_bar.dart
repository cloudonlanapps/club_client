import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';

/// The top of an evaluation page: **Back** ([onBack], no confirmation —
/// answers autosave) and/or a page [title] on the left, and [trailing] (the
/// download icon) at the top right.
class EvaluationTopBar extends StatelessWidget {
  /// A top bar; every part is optional.
  const EvaluationTopBar({this.onBack, this.title, this.trailing, super.key});

  /// Leaves the page, when given.
  final VoidCallback? onBack;

  /// The page's title, when given.
  final String? title;

  /// The action at the top right.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    final heading = title;
    return Row(
      spacing: EvaluationViewSizes.smallGap,
      children: [
        if (back != null)
          ShadButton.ghost(
            onPressed: back,
            leading: const Icon(LucideIcons.arrowLeft),
            child: const Text(EvaluationViewStrings.back),
          ),
        Expanded(
          child: heading == null
              ? const SizedBox.shrink()
              : Text(heading, style: ShadTheme.of(context).textTheme.h3),
        ),
        ?trailing,
      ],
    );
  }
}
