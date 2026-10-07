import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The shared layout of the credit forms (club_core#101): a [ShadForm] of
/// stacked [fields] and, under them, the inline form-level [error] a
/// cross-field rule raised on submit.
class CreditFormBody extends StatelessWidget {
  const CreditFormBody({
    required this.formKey,
    required this.initialValue,
    required this.fields,
    this.error,
    super.key,
  });

  final GlobalKey<ShadFormState> formKey;
  final Map<String, dynamic> initialValue;
  final List<Widget> fields;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      initialValue: initialValue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          ...fields,
          if (error != null)
            Text(
              error!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
        ],
      ),
    );
  }
}
