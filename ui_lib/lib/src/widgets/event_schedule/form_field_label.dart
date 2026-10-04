import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel({
    required this.label,
    this.isRequired = false,
    this.style,
    super.key,
  });
  final String label;
  final bool isRequired;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultStyle = theme.textTheme.small.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.foreground,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: style ?? defaultStyle,
          children: isRequired
              ? [
                  TextSpan(
                    text: ' *',
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.destructive,
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
