import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/profile_label_language.dart';
import '../event_marketing/marketing_values_equal.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'profile_languages_field.dart';
import 'profile_options_form_fields.dart';
import 'profile_options_form_strings.dart';
import 'profile_options_form_validators.dart';
import 'profile_options_form_values.dart';
import 'profile_positions_field.dart';

/// Pure-UI editor for the club's choices of the extended profile: the
/// positions a member may prefer, each with a stored value and a label per
/// language of [labelLanguages] (English required), and the languages a
/// member may prefer, by name. Rows are added and removed; positions are
/// also moved up and down.
///
/// [initialValues] has the shape [ProfileOptionsFormState.validate]
/// returns. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ProfileOptionsFormState>` ([FormContract]).
class ProfileOptionsForm extends StatefulWidget {
  const ProfileOptionsForm({
    required this.initialValues,
    required this.labelLanguages,
    this.enabled = true,
    super.key,
  });

  /// The options to start from: [ProfileOptionsFormFields.positionsId] and
  /// [ProfileOptionsFormFields.languagesId].
  final Map<String, dynamic> initialValues;

  /// The languages a position gets a label in, in order, each with the
  /// name shown above its input. A label a position has in another
  /// language is kept and returned, unshown.
  final List<ProfileLabelLanguage> labelLanguages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ProfileOptionsForm> createState() => ProfileOptionsFormState();
}

/// State of [ProfileOptionsForm]. Its value is
/// `{positionsId: [{valueKey: String, labelKey: {code: String}}],
/// languagesId: [String]}`, texts trimmed and empty labels left out.
class ProfileOptionsFormState extends State<ProfileOptionsForm>
    with FormContract<ProfileOptionsForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ProfileOptionsFormFields.positionsId: ProfileOptionsFormValues.positionsOut(
      values[ProfileOptionsFormFields.positionsId],
    ),
    ProfileOptionsFormFields.languagesId: ProfileOptionsFormValues.languagesOut(
      values[ProfileOptionsFormFields.languagesId],
    ),
  };

  /// Whether anything differs from its initial value. Overridden because
  /// both values are lists, of maps for the positions: an edit gives the
  /// field a new list, which `mapEquals` would compare by identity, so the
  /// lists are compared item by item (rule 8).
  @override
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !marketingValuesEqual(form.initialValue, form.value);
  }

  /// The two lists have nothing to put the focus on.
  @override
  bool get focusFirstInvalid => false;

  @override
  Widget build(BuildContext context) {
    final languages = widget.labelLanguages;
    return ShadForm(
      key: formKey,
      initialValue: {
        ProfileOptionsFormFields.positionsId:
            ProfileOptionsFormValues.positions(
              widget.initialValues[ProfileOptionsFormFields.positionsId],
              languages,
            ),
        ProfileOptionsFormFields.languagesId:
            ProfileOptionsFormValues.languages(
              widget.initialValues[ProfileOptionsFormFields.languagesId],
            ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ProfileOptionsFormStrings.positions,
            field: ProfilePositionsField(
              id: ProfileOptionsFormFields.positionsId,
              labelLanguages: languages,
              enabled: widget.enabled,
              validator: ProfileOptionsFormValidators.positions(languages),
            ),
          ),
          LabeledFormRow(
            label: ProfileOptionsFormStrings.languages,
            field: ProfileLanguagesField(
              id: ProfileOptionsFormFields.languagesId,
              enabled: widget.enabled,
              validator: ProfileOptionsFormValidators.languages,
            ),
          ),
        ],
      ),
    );
  }
}
