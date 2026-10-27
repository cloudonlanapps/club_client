import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_language_option.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_form_values.dart';
import 'application_section_contract.dart';
import 'items/application_items_field.dart';
import 'sections/application_age_category_editor.dart';
import 'sections/application_age_category_values.dart';

/// Pure-UI section editor of an application's age categories, printed
/// with the member's ticked: each a name (English required, the other
/// print language offered), an "Age limit applicable" tick with, while
/// ticked, first and last birth dates (at least one, in order), and the
/// genders it takes (none ticked: all). Categories are added, removed and
/// moved, and may overlap.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationAgeCategoriesFormState>`
/// ([FormContract]).
class ApplicationAgeCategoriesForm extends StatefulWidget {
  const ApplicationAgeCategoriesForm({
    required this.initialValues,
    required this.languages,
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationAgeCategoriesForm> createState() =>
      ApplicationAgeCategoriesFormState();
}

/// State of [ApplicationAgeCategoriesForm]. Its value is the list of
/// categories under `ageCategoriesId`, each as the template holds it plus
/// its tick: a `label` by language, `age_limit` and, when given,
/// `born_on_or_after` and `born_on_or_before` (only while `age_limit`) and
/// `genders`.
class ApplicationAgeCategoriesFormState
    extends State<ApplicationAgeCategoriesForm>
    with
        FormContract<ApplicationAgeCategoriesForm>,
        ApplicationSectionContract<ApplicationAgeCategoriesForm> {
  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.ageCategoriesId: ApplicationFormValues.list(
          widget.initialValues[ApplicationFormFields.ageCategoriesId],
          ApplicationAgeCategoryValues.category,
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.ageCategories,
            field: ApplicationItemsField(
              id: ApplicationFormFields.ageCategoriesId,
              enabled: widget.enabled,
              noun: ApplicationFormStrings.ageCategoryNoun,
              addLabel: ApplicationFormStrings.addAgeCategory,
              newItem: () => ApplicationAgeCategoryValues.category(null),
              validator: (items) => ApplicationFormValidators.items(
                items,
                ApplicationFormStrings.ageCategoryNoun,
                ApplicationFormValidators.ageCategory,
              ),
              itemBuilder:
                  ({required initial, required onChanged, required enabled}) =>
                      ApplicationAgeCategoryEditor(
                        initial: initial,
                        languages: widget.languages,
                        enabled: enabled,
                        onChanged: onChanged,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
