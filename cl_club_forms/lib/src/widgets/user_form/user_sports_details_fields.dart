import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/profile_position_option.dart';
import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_optional_choice_field.dart';

/// The sports details of the extended profile: club or district, preferred
/// position and past experience. Sits inside the embedding form's
/// `ShadForm`, which holds the initial values.
class UserSportsDetailsFields extends StatelessWidget {
  const UserSportsDetailsFields({
    required this.positions,
    this.enabled = true,
    super.key,
  });

  /// Fewest lines the past experience shows.
  static const int pastExperienceMinLines = 3;

  /// Most lines the past experience grows to.
  static const int pastExperienceMaxLines = 6;

  /// The club's positions, in order.
  final List<ProfilePositionOption> positions;

  /// Whether the fields respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBody(
      children: [
        LabeledFormRow(
          label: UserFormStrings.clubDistrict,
          field: ShadInputFormField(
            id: UserFormFields.clubDistrictId,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.preferredPosition,
          field: UserOptionalChoiceField(
            id: UserFormFields.preferredPositionsId,
            enabled: enabled,
            options: {
              for (final position in positions) position.value: position.label,
            },
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.pastExperience,
          field: ShadInputFormField(
            id: UserFormFields.pastExperienceId,
            keyboardType: TextInputType.multiline,
            minLines: pastExperienceMinLines,
            maxLines: pastExperienceMaxLines,
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}
