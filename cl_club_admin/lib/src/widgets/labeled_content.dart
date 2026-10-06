import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A muted label stacked over [child].
class LabeledContent extends StatelessWidget {
  /// [child] under [label].
  const LabeledContent({required this.label, required this.child, super.key});

  /// What the content is.
  final String label;

  /// The content.
  final Widget child;

  /// Gap between the label and the content.
  static const double labelGap = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: labelGap,
      children: [
        Text(label, style: ShadTheme.of(context).textTheme.muted),
        child,
      ],
    );
  }
}
