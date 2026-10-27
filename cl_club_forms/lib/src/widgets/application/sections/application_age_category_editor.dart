import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_choice_option.dart';
import '../../../models/application/application_custom_text.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_fields.dart';
import '../application_form_strings.dart';
import '../facts/application_choices_input.dart';
import '../facts/application_date_input.dart';
import '../text_value/application_text_value_editor.dart';
import 'application_age_category_values.dart';

/// Edits one age category of an application: its name in each print
/// language, whether an age limit applies and, while it does, the first
/// and last birth dates it takes (at least one, each cleared by its
/// button), and the genders it takes (none ticked: all). Unticking the
/// age limit hides the dates and sends none; ticking it again brings
/// back the ones picked.
///
/// It reports the category as `ApplicationAgeCategoryValues.category`
/// shapes it through [onChanged] on every edit; it is seeded once from
/// [initial].
class ApplicationAgeCategoryEditor extends StatefulWidget {
  const ApplicationAgeCategoryEditor({
    required this.initial,
    required this.languages,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The category to start from.
  final Object? initial;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// Called with the category after every edit.
  final ValueChanged<Object?> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationAgeCategoryEditor> createState() =>
      ApplicationAgeCategoryEditorState();
}

/// State of [ApplicationAgeCategoryEditor]: what the category holds.
class ApplicationAgeCategoryEditorState
    extends State<ApplicationAgeCategoryEditor> {
  /// The category's name.
  ApplicationTextValue? label;

  /// Whether the category limits birth dates.
  bool ageLimit = false;

  /// The first birth date; `''` for none.
  String bornOnOrAfter = '';

  /// The last birth date; `''` for none.
  String bornOnOrBefore = '';

  /// The genders ticked.
  List<String> genders = const [];

  @override
  void initState() {
    super.initState();
    final category = ApplicationAgeCategoryValues.category(widget.initial);
    label = ApplicationTextValue.fromJson(
      category[ApplicationFormFields.labelKey],
    );
    ageLimit = category[ApplicationFormFields.ageLimitKey]! as bool;
    bornOnOrAfter =
        category[ApplicationFormFields.bornOnOrAfterKey] as String? ?? '';
    bornOnOrBefore =
        category[ApplicationFormFields.bornOnOrBeforeKey] as String? ?? '';
    genders =
        category[ApplicationFormFields.gendersKey] as List<String>? ?? const [];
  }

  /// Takes up [changed], then reports.
  void update(VoidCallback changed) {
    setState(changed);
    final name = label;
    widget.onChanged(
      ApplicationAgeCategoryValues.build(
        label: name is ApplicationCustomText ? name.text : const {},
        ageLimit: ageLimit,
        bornOnOrAfter: bornOnOrAfter,
        bornOnOrBefore: bornOnOrBefore,
        genders: genders,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LabeledFormRow date(String text, String value, ValueChanged<String> set) =>
        LabeledFormRow(
          label: text,
          field: ApplicationDateInput(
            value: value,
            enabled: widget.enabled,
            onChanged: (day) => update(() => set(day)),
            onCleared: () => update(() => set('')),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        ApplicationTextValueEditor(
          languages: widget.languages,
          label: ApplicationFormStrings.ageCategoryName,
          requireEnglish: true,
          initialValue: label,
          enabled: widget.enabled,
          onChanged: (value) => update(() => label = value),
        ),
        ShadCheckbox(
          value: ageLimit,
          enabled: widget.enabled,
          label: const Text(ApplicationFormStrings.ageLimitApplicable),
          onChanged: (ticked) => update(() => ageLimit = ticked),
        ),
        if (ageLimit) ...[
          date(
            ApplicationFormStrings.bornOnOrAfter,
            bornOnOrAfter,
            (day) => bornOnOrAfter = day,
          ),
          date(
            ApplicationFormStrings.bornOnOrBefore,
            bornOnOrBefore,
            (day) => bornOnOrBefore = day,
          ),
        ],
        LabeledFormRow(
          label: ApplicationFormStrings.genders,
          field: ApplicationChoicesInput(
            options: [
              for (final gender in ApplicationAgeCategoryValues.genders)
                ApplicationChoiceOption(
                  id: gender,
                  text: {
                    ApplicationFormFields.english:
                        ApplicationFormStrings.genderName(gender),
                  },
                ),
            ],
            value: genders,
            enabled: widget.enabled,
            onChanged: (ticked) => update(() => genders = ticked),
          ),
        ),
      ],
    );
  }
}
