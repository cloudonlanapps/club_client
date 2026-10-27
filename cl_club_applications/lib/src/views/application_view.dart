import 'dart:typed_data';

import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationCompleteness, ApplicationFactGaps;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        applicationClausesProvider,
        applicationLabelsProvider,
        applicationsProvider,
        clApplicationsMasterProvider,
        emptyApplicationClauses,
        emptyApplicationLabels;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationStatus, ApplicationTemplate, UserPrivate;
import 'package:flutter/material.dart' show Divider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction, TitleRow;

import '../constants/application_fact_strings.dart';
import '../constants/application_view_strings.dart';
import '../models/application_editor_options.dart';
import '../models/application_form_submit.dart';
import '../models/application_section.dart';
import '../utils/application_label_gaps.dart';
import '../utils/application_places.dart';
import '../utils/application_title.dart';
import '../widgets/application_export_button.dart';
import '../widgets/application_page.dart';
import '../widgets/application_state_card.dart';
import '../widgets/sections/application_section_card.dart';

/// The admin's editor of one application template at
/// `/memberzone/applications/:id` (club_client#321, design §2): the State
/// card — state, stored layout, the moves and Preview — then the template
/// in sections, each editing in place while it is a draft.
///
/// Renders nothing unless the server offers applications.
class ApplicationView extends ConsumerWidget {
  const ApplicationView({
    required this.currentUser,
    required this.applicationId,
    required this.onBack,
    required this.onDeleted,
    required this.pdfAction,
    required this.onSaveFile,
    super.key,
  });

  /// The signed-in admin.
  final UserPrivate currentUser;

  /// The template's id.
  final int applicationId;

  /// Leaves the editor.
  final VoidCallback onBack;

  /// Leaves the editor once the template is deleted.
  final VoidCallback onDeleted;

  /// What the downloaded preview is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Saves a file of this name and these bytes (Export JSON); resolves to
  /// whether it was saved.
  final Future<bool> Function(String fileName, Uint8List bytes) onSaveFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.isAdmin,
      'ApplicationView called for ${currentUser.username}, who is not an '
      'admin. ApplicationScreen gate (RoleGate.admin) failed.',
    );
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    final templates = ref.watch(clApplicationsMasterProvider);
    final labels = ref.watch(applicationLabelsProvider);
    final clauses = ref.watch(applicationClausesProvider);
    final first = [templates, labels, clauses];
    if (first.any((v) => v.isLoading && !v.hasValue)) {
      return const Center(child: ShadProgress());
    }
    final template = templates.valueOrNull?[applicationId];
    if (template == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleRow(title: ApplicationViewStrings.applications, onBack: onBack),
          const Divider(height: 1),
          ApplicationPage(
            children: [
              Text(
                templates.hasValue
                    ? ApplicationViewStrings.notFound
                    : ApplicationViewStrings.loadFailed,
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
        ],
      );
    }
    final options = ApplicationEditorOptions.from(
      labels.valueOrNull ?? emptyApplicationLabels,
      clauses.valueOrNull ?? emptyApplicationClauses,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(title: applicationTitle(template), onBack: onBack),
        const Divider(height: 1),
        Expanded(
          child: ApplicationEditorBody(
            template: template,
            options: options,
            checkTexts: clauses.hasValue,
            onDeleted: onDeleted,
            pdfAction: pdfAction,
            onSaveFile: onSaveFile,
          ),
        ),
      ],
    );
  }
}

/// The editor's page: the heading card and the sections of [template],
/// then, once finalized, Export JSON at its foot.
class ApplicationEditorBody extends StatelessWidget {
  const ApplicationEditorBody({
    required this.template,
    required this.options,
    required this.checkTexts,
    required this.onDeleted,
    required this.pdfAction,
    required this.onSaveFile,
    super.key,
  });

  /// The template.
  final ApplicationTemplate template;

  /// What the forms choose from.
  final ApplicationEditorOptions options;

  /// Whether the clause library is read, so the client's check of the
  /// texts can run.
  final bool checkTexts;

  /// Leaves the editor once the template is deleted.
  final VoidCallback onDeleted;

  /// What the downloaded preview is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Saves the exported JSON file.
  final Future<bool> Function(String fileName, Uint8List bytes) onSaveFile;

  @override
  Widget build(BuildContext context) {
    final json = buildApplicationFormInitialValues(template);
    final draft = template.status == ApplicationStatus.draft;
    final missing = draft && checkTexts
        ? [
            for (final MapEntry(key: place, value: languages)
                in ApplicationCompleteness.missingLanguages(json).entries)
              ApplicationViewStrings.missingText(
                ApplicationPlaces.label(place),
                [
                  for (final code in languages)
                    ApplicationViewStrings.languageName(code),
                ],
              ),
            // The club's labels, as Finalize checks them (club_client#396).
            for (final gap in applicationLabelGaps(options.labels, json))
              ApplicationViewStrings.missingLabel(gap.name, [
                for (final code in gap.languages)
                  ApplicationViewStrings.languageName(code),
              ]),
          ]
        : const <String>[];
    // Gaps naming no fact are checked from the template alone, as Save
    // checks them (club_client#389).
    final unknownFacts = draft
        ? [
            for (final gap in ApplicationFactGaps.unknown(json))
              ApplicationFactStrings.unknownFact(
                ApplicationPlaces.label(gap.place),
                ApplicationViewStrings.languageName(gap.language),
                gap.name,
              ),
          ]
        : const <String>[];
    return ApplicationPage(
      children: [
        ApplicationStateCard(
          template: template,
          missing: missing,
          unknownFacts: unknownFacts,
          onDeleted: onDeleted,
          pdfAction: pdfAction,
        ),
        for (final section in ApplicationSection.values)
          ApplicationSectionCard(
            template: template,
            json: json,
            section: section,
            options: options,
            canEdit: draft,
          ),
        // Apart from the moves in the heading card: a finalized template
        // can be carried to another server as a file.
        if (!draft)
          Align(
            alignment: Alignment.centerRight,
            child: ApplicationExportButton(
              template: template,
              onSaveFile: onSaveFile,
            ),
          ),
      ],
    );
  }
}
