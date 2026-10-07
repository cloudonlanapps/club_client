import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The inside of a club details section card, read or being edited: what
/// the section is for, when it says, above its rows or its form.
class ClubIdentitySectionBody extends StatelessWidget {
  const ClubIdentitySectionBody({
    required this.child,
    this.description,
    super.key,
  });

  /// The widest a section's form grows.
  static const double formMaxWidth = 560;

  /// Gap between the description and [child].
  static const double descriptionGap = 16;

  /// What the section's values are used for; null shows nothing.
  final String? description;

  /// The section's rows, or its form.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final help = description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: descriptionGap,
      children: [
        if (help != null)
          Text(help, style: ShadTheme.of(context).textTheme.muted),
        child,
      ],
    );
  }
}
