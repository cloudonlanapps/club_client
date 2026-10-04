import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A muted label stacked over a selectable value.
class LabeledValue extends StatelessWidget {
  const LabeledValue({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(label, style: theme.textTheme.muted),
        SelectableText(value, style: theme.textTheme.p),
      ],
    );
  }
}
