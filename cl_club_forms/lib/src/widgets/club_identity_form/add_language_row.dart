import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'club_identity_form_validators.dart';

/// The languages `ClubIdentityForm` offers translations in, and an input to
/// add one by its code. The code is not a document field, so the input is a
/// plain `ShadInput`, not registered with the form.
class AddLanguageRow extends StatefulWidget {
  const AddLanguageRow({
    required this.languages,
    required this.onAdd,
    this.enabled = true,
    super.key,
  });

  /// The languages already offered.
  final List<String> languages;

  /// Called with a valid code not already offered.
  final ValueChanged<String> onAdd;

  final bool enabled;

  @override
  State<AddLanguageRow> createState() => AddLanguageRowState();
}

class AddLanguageRowState extends State<AddLanguageRow> {
  final TextEditingController controller = TextEditingController();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void add() {
    final code = controller.text.trim();
    final problem =
        ClubIdentityFormValidators.languageCode(code) ??
        (widget.languages.contains(code) ? '$code is already offered' : null);
    setState(() => error = problem);
    if (problem != null) return;
    controller.clear();
    widget.onAdd(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final problem = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          widget.languages.isEmpty
              ? 'Translations: none yet — every field shows its default text.'
              : 'Translations: ${widget.languages.join(', ')}',
          style: theme.textTheme.small,
        ),
        Text(
          'Add a language code',
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: ShadInput(
                key: const ValueKey('clubIdentity.addLanguage'),
                controller: controller,
                enabled: widget.enabled,
                placeholder: const Text('e.g. mr or hi'),
                keyboardType: TextInputType.text,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) => add(),
              ),
            ),
            ShadButton.outline(
              key: const ValueKey('clubIdentity.addLanguage.add'),
              onPressed: widget.enabled ? add : null,
              child: const Text('Add language'),
            ),
          ],
        ),
        if (problem != null)
          Text(
            problem,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
      ],
    );
  }
}
