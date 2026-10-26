import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_breakpoints.dart';
import '../../constants/form_spacing.dart';
import '../../models/profile_label_language.dart';
import '../form/labeled_form_row.dart';
import 'profile_option_row_frame.dart';
import 'profile_options_form_fields.dart';
import 'profile_options_form_strings.dart';
import 'profile_position_actions.dart';

/// One position of `ProfileOptionsForm`: its value and a label per
/// language, each typed into its controller, and the row's buttons. The
/// cells sit side by side on a wide editor and stack on a narrow one.
class ProfilePositionRow extends StatelessWidget {
  const ProfilePositionRow({
    required this.labelLanguages,
    required this.valueController,
    required this.labelControllers,
    required this.enabled,
    required this.onChanged,
    required this.actions,
    super.key,
  });

  /// The languages a label is typed in, in order.
  final List<ProfileLabelLanguage> labelLanguages;

  /// The text of the value.
  final TextEditingController valueController;

  /// The text of each label, by language code.
  final Map<String, TextEditingController> labelControllers;

  /// Whether the inputs respond.
  final bool enabled;

  /// Called after any of the row's texts changes.
  final VoidCallback onChanged;

  /// The row's buttons.
  final ProfilePositionActions actions;

  @override
  Widget build(BuildContext context) {
    final cells = [
      LabeledFormRow(
        label: ProfileOptionsFormStrings.positionValue,
        required: true,
        field: ShadInput(
          controller: valueController,
          enabled: enabled,
          keyboardType: TextInputType.text,
          onChanged: (_) => onChanged(),
        ),
      ),
      for (final language in labelLanguages)
        LabeledFormRow(
          label: language.name,
          required:
              language.code == ProfileOptionsFormFields.requiredLabelLanguage,
          field: ShadInput(
            controller: labelControllers[language.code],
            enabled: enabled,
            keyboardType: TextInputType.text,
            onChanged: (_) => onChanged(),
          ),
        ),
    ];
    return ProfileOptionRowFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < FormBreakpoints.singleColumnMaxWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FormSpacing.rowGap,
              children: [
                ...cells,
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: FormSpacing.rowGap,
            children: [
              for (final cell in cells) Expanded(child: cell),
              actions,
            ],
          );
        },
      ),
    );
  }
}
