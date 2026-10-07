// The example is the package's own host, and reaches every form's state
// through the contract they share, which the barrel does not export.
// ignore: implementation_imports
import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/demo_keys.dart';
import '../constants/demo_sizes.dart';
import '../models/form_demo_entry.dart';

/// The main view: the form of [entry] mounted bare, with its sample data,
/// inside one plain card. The demo draws nothing else around the form; its
/// own controls are in the top bar.
class FormPreview extends StatelessWidget {
  /// Creates the preview of [entry].
  const FormPreview({required this.entry, required this.formKey, super.key});

  /// The entry whose form is shown.
  final FormDemoEntry entry;

  /// The key the form is mounted with. A new key mounts the form afresh.
  final GlobalKey<FormContract> formKey;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DemoSizes.pagePadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: entry.maxWidth),
          child: Container(
            key: DemoKeys.formCard,
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              border: Border.all(color: theme.colorScheme.border),
              borderRadius: BorderRadius.circular(DemoSizes.radius),
            ),
            padding: const EdgeInsets.all(DemoSizes.pagePadding),
            child: entry.builder(formKey),
          ),
        ),
      ),
    );
  }
}
