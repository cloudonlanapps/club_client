import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_option.dart';
import '../../models/application/application_clause_text.dart';
import '../../models/application/application_fact_type.dart';
import '../../models/application/application_language_option.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_form_values.dart';
import 'application_section_contract.dart';
import 'application_text_sources.dart';
import 'items/application_items_field.dart';
import 'sections/application_header_item_editor.dart';

/// Pure-UI section editor of an application's header strip: short items
/// (the venue, the dates, a phone), each a header clause of the library
/// with its gaps bound to the template's facts, a fact, or written in each
/// print language; several may be joined on one line. Items are added,
/// removed and moved.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationHeaderFormState>` ([FormContract]).
class ApplicationHeaderForm extends StatefulWidget {
  const ApplicationHeaderForm({
    required this.initialValues,
    required this.languages,
    this.facts = const {},
    this.clauses = const [],
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The template's facts: the type of each, by name.
  final Map<String, ApplicationFactType> facts;

  /// The clause library; its header clauses are offered.
  final List<ApplicationClauseOption> clauses;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationHeaderForm> createState() => ApplicationHeaderFormState();
}

/// State of [ApplicationHeaderForm]. Its value is `{headerId: [item]}`,
/// each item as the template holds it: a text, or a list of texts joined
/// on one line.
class ApplicationHeaderFormState extends State<ApplicationHeaderForm>
    with
        FormContract<ApplicationHeaderForm>,
        ApplicationSectionContract<ApplicationHeaderForm> {
  @override
  Widget build(BuildContext context) {
    final sources = ApplicationTextSources(
      facts: widget.facts,
      clauses: widget.clauses,
    );
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.headerId: ApplicationFormValues.list(
          widget.initialValues[ApplicationFormFields.headerId],
          ApplicationFormValues.text,
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.header,
            field: ApplicationItemsField(
              id: ApplicationFormFields.headerId,
              enabled: widget.enabled,
              noun: ApplicationFormStrings.headerItemNoun,
              addLabel: ApplicationFormStrings.addHeaderItem,
              newItem: () => const ApplicationClauseText('').toJson(),
              validator: (items) => ApplicationFormValidators.items(
                items,
                ApplicationFormStrings.headerItemNoun,
                (item) => ApplicationFormValidators.text(
                  item,
                  sources,
                  required: true,
                  kind: ApplicationClauseKind.header,
                ),
              ),
              itemBuilder:
                  ({required initial, required onChanged, required enabled}) =>
                      ApplicationHeaderItemEditor(
                        initial: initial,
                        languages: widget.languages,
                        sources: sources,
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
