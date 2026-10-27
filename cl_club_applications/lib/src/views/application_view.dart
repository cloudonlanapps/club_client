import 'package:cl_club_forms/cl_club_forms.dart' show ApplicationCompleteness;
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

import '../constants/application_view_strings.dart';
import '../models/application_editor_options.dart';
import '../models/application_form_submit.dart';
import '../models/application_section.dart';
import '../utils/application_places.dart';
import '../utils/application_title.dart';
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
          ),
        ),
      ],
    );
  }
}

/// The editor's page: the State card and the sections of [template].
class ApplicationEditorBody extends StatelessWidget {
  const ApplicationEditorBody({
    required this.template,
    required this.options,
    required this.checkTexts,
    required this.onDeleted,
    required this.pdfAction,
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

  @override
  Widget build(BuildContext context) {
    final json = buildApplicationFormInitialValues(template);
    final draft = template.status == ApplicationStatus.draft;
    final missing = draft && checkTexts
        ? [
            for (final place in ApplicationCompleteness.missingTexts(json))
              ApplicationPlaces.label(place),
          ]
        : const <String>[];
    return ApplicationPage(
      children: [
        ApplicationStateCard(
          template: template,
          missing: missing,
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
      ],
    );
  }
}
