import 'package:flutter/foundation.dart' show listEquals;
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
/// language of the club (English required), and the club's languages, each
/// a name a member may prefer and a code (club_client#396), English first
/// and fixed. The positions' labels follow the languages as they are
/// edited. Rows are added and removed; positions are also moved up and
/// down.
///
/// [initialValues] has the shape [ProfileOptionsFormState.validate]
/// returns. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ProfileOptionsFormState>` ([FormContract]).
class ProfileOptionsForm extends StatefulWidget {
  const ProfileOptionsForm({
    required this.initialValues,
    this.enabled = true,
    super.key,
  });

  /// The options to start from: [ProfileOptionsFormFields.positionsId] and
  /// [ProfileOptionsFormFields.languagesId].
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ProfileOptionsForm> createState() => ProfileOptionsFormState();
}

/// State of [ProfileOptionsForm]. Its value is
/// `{positionsId: [{valueKey: String, labelKey: {code: String}}],
/// languagesId: [{codeKey: String, nameKey: String}]}`, texts trimmed,
/// English first, and empty labels and labels in a language not listed
/// left out.
class ProfileOptionsFormState extends State<ProfileOptionsForm>
    with FormContract<ProfileOptionsForm> {
  /// The languages a position gets a label in: those the languages list
  /// holds now, each with a code.
  late List<ProfileLabelLanguage> labelLanguages =
      ProfileOptionsFormValues.labelLanguages(
        widget.initialValues[ProfileOptionsFormFields.languagesId],
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final languages = values[ProfileOptionsFormFields.languagesId];
    return {
      ProfileOptionsFormFields.positionsId:
          ProfileOptionsFormValues.positionsOut(
            values[ProfileOptionsFormFields.positionsId],
            [
              for (final l in ProfileOptionsFormValues.languagesOut(languages))
                l[ProfileOptionsFormFields.codeKey]!,
            ],
          ),
      ProfileOptionsFormFields.languagesId:
          ProfileOptionsFormValues.languagesOut(languages),
    };
  }

  /// Follows an edit of the languages with the positions' labels.
  void languagesChanged(List<Object?>? languages) {
    final next = ProfileOptionsFormValues.labelLanguages(languages);
    if (listEquals(next, labelLanguages)) return;
    setState(() => labelLanguages = next);
  }

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
    final languages = labelLanguages;
    return ShadForm(
      key: formKey,
      initialValue: {
        ProfileOptionsFormFields.positionsId:
            ProfileOptionsFormValues.positions(
              widget.initialValues[ProfileOptionsFormFields.positionsId],
              ProfileOptionsFormValues.labelLanguages(
                widget.initialValues[ProfileOptionsFormFields.languagesId],
              ),
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
              onChanged: languagesChanged,
              validator: ProfileOptionsFormValidators.languages,
            ),
          ),
        ],
      ),
    );
  }
}
