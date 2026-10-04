import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A group heading over a list of rows, with an optional [trailing] action.
class EvaluationHeading extends StatelessWidget {
  /// Heads a group titled [text].
  const EvaluationHeading({required this.text, this.trailing, super.key});

  /// The heading.
  final String text;

  /// An action at the end of the heading row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(text, style: ShadTheme.of(context).textTheme.h4)),
      ?trailing,
    ],
  );
}
