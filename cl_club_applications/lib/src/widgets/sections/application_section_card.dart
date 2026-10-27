import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../../constants/application_view_sizes.dart';
import '../../constants/application_view_strings.dart';
import '../../models/application_editor_options.dart';
import '../../models/application_form_submit.dart';
import '../../models/application_section.dart';
import '../../utils/application_section_lines.dart';
import '../../utils/application_text_reader.dart';
import '../application_facts_help.dart';
import 'application_section_read.dart';
import 'application_section_specs.dart';

/// One section of the application editor (club_client#321): an
/// [EditableSectionCard] whose read mode shows the section as it prints and
/// whose editor is the section's `cl_club_forms` form. Save sends this
/// section's fields alone.
///
/// Editable only while the template is a draft ([canEdit]). A value the
/// server refuses shows on its field; a template no longer a draft is said
/// inline in the form, and the list reloads; anything else is a toast.
class ApplicationSectionCard extends ConsumerStatefulWidget {
  const ApplicationSectionCard({
    required this.template,
    required this.json,
    required this.section,
    required this.options,
    required this.canEdit,
    super.key,
  });

  /// The template.
  final ApplicationTemplate template;

  /// The template as the forms hold it.
  final Map<String, dynamic> json;

  /// Which section this is.
  final ApplicationSection section;

  /// What the forms choose from.
  final ApplicationEditorOptions options;

  /// Whether the viewer may edit it now.
  final bool canEdit;

  @override
  ConsumerState<ApplicationSectionCard> createState() =>
      ApplicationSectionCardState();
}

/// State of [ApplicationSectionCard]: the key of its form.
class ApplicationSectionCardState
    extends ConsumerState<ApplicationSectionCard> {
  /// Drives the hosted form.
  final GlobalKey formKey = GlobalKey();

  /// Saves [values]; true once saved.
  Future<bool> save(Map<String, dynamic> values) async {
    final spec = ApplicationSectionSpecs.of(widget.section);
    try {
      await spec.save(
        id: widget.template.id,
        values: values,
        notifier: ref.read(clApplicationsMasterProvider.notifier),
      );
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            description: Text(
              ApplicationViewStrings.sectionSaved(widget.section.title),
            ),
          ),
        );
      }
      return true;
    } on Object catch (e) {
      if (!mounted) return false;
      final fieldErrors = ApplicationFormSubmit.fieldErrorsFor(e);
      if (fieldErrors.isNotEmpty) {
        spec.showErrors(formKey, fieldErrors: fieldErrors);
      } else if (ApplicationFormSubmit.isNotDraft(e)) {
        spec.showErrors(
          formKey,
          formError: ApplicationViewStrings.notDraftAnymore,
        );
        ref.invalidate(clApplicationsMasterProvider);
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text(ApplicationViewStrings.writeFailed),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = ApplicationSectionSpecs.of(widget.section);
    final reader = ApplicationTextReader(
      template: widget.json,
      options: widget.options,
    );
    final lines = ApplicationSectionLines.of(widget.section, reader);
    return EditableSectionCard<Map<String, dynamic>>(
      key: ValueKey(widget.section.cardKey),
      title: widget.section.title,
      titleTrailing: widget.section == ApplicationSection.facts
          ? const ApplicationFactsHelp()
          : null,
      canEdit: widget.canEdit,
      isEmpty: lines.isEmpty,
      emptyHint: ApplicationViewStrings.emptySection,
      editMaxWidth: ApplicationViewSizes.editMaxWidth,
      read: ApplicationSectionRead(
        lines: lines,
        required: ApplicationSectionLines.requiredLabels(widget.section),
      ),
      editBuilder: ({required enabled}) =>
          spec.build(formKey, widget.json, widget.options, enabled: enabled),
      onValidate: () => spec.validate(formKey),
      isDirty: () => spec.isDirty(formKey),
      onSave: save,
    );
  }
}
