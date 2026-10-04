import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One entry of the add menu: an icon and a label.
class EvaluationAddMenuEntry extends StatelessWidget {
  /// Offers [label].
  const EvaluationAddMenuEntry({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// The entry's icon.
  final IconData icon;

  /// What it adds.
  final String label;

  /// Adds it.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ShadButton.ghost(
    mainAxisAlignment: MainAxisAlignment.start,
    leading: Icon(icon),
    onPressed: onPressed,
    child: Text(label),
  );
}
