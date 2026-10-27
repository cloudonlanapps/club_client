import 'package:cl_remote_store/cl_remote_store.dart'
    show applicationLabelsProvider, clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationStatus, ApplicationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog, PdfAction;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import '../models/application_step.dart';
import '../utils/application_save_refusal.dart';
import '../utils/application_title.dart';
import 'application_download_button.dart';
import 'application_missing_texts.dart';
import 'application_publish_id.dart';
import 'application_step_button.dart';
import 'application_unknown_facts.dart';

/// The heading card of the application editor (club_client#321, #398): the
/// template's title and state, with Preview and, once finalized, Download
/// blank form (club_client#393) as icons on the right; a published
/// template's publish ID (club_client#339); and the moves its state allows
/// (Finalize, Publish, Unpublish, Revert to draft, Delete).
///
/// A move the state does not allow is not shown. Finalize (the save move)
/// is greyed out while the client's check finds texts [missing], or
/// `{gap}`s naming no fact ([unknownFacts], club_client#389), which it
/// lists in the error colour. Delete is an icon at the bottom right.
/// What the server refuses about the template on Finalize shows inline
/// here, never as a toast.
class ApplicationStateCard extends ConsumerStatefulWidget {
  const ApplicationStateCard({
    required this.template,
    required this.missing,
    required this.onDeleted,
    required this.pdfAction,
    this.unknownFacts = const [],
    super.key,
  });

  /// The template.
  final ApplicationTemplate template;

  /// The texts the client's check finds missing, as shown; empty when none
  /// or while the library is not read.
  final List<String> missing;

  /// The `{gap}`s naming no fact of the template, as shown
  /// (club_client#389); empty when none.
  final List<String> unknownFacts;

  /// Leaves the editor once the template is deleted.
  final VoidCallback onDeleted;

  /// What the downloaded preview and blank form are handed to: shared,
  /// saved or opened.
  final PdfAction pdfAction;

  @override
  ConsumerState<ApplicationStateCard> createState() =>
      ApplicationStateCardState();
}

/// State of [ApplicationStateCard]: the move in flight and the last
/// refusal.
class ApplicationStateCardState extends ConsumerState<ApplicationStateCard> {
  /// The move running, if any.
  ApplicationStep? running;

  /// What the server refused about the template on Save; null for none.
  String? refusal;

  /// Shows [message] as a toast; [failed] makes it destructive.
  void toast(String message, {bool failed = false}) {
    final text = Text(message);
    ShadToaster.of(context).show(
      failed
          ? ShadToast.destructive(description: text)
          : ShadToast(description: text),
    );
  }

  /// Runs [step], asking first for Delete.
  Future<void> run(ApplicationStep step) async {
    if (step == ApplicationStep.delete) {
      final ok = await ConfirmDialog.show(
        context,
        title: ApplicationViewStrings.deleteTitle,
        message: ApplicationViewStrings.deleteMessage,
        confirmLabel: step.label,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      running = step;
      refusal = null;
    });
    try {
      final notifier = ref.read(clApplicationsMasterProvider.notifier);
      await step.run(notifier, widget.template.id);
      if (!mounted) return;
      toast(step.doneMessage);
      if (step == ApplicationStep.delete) widget.onDeleted();
    } on Object catch (e) {
      if (!mounted) return;
      final message = applicationSaveRefusal(
        e,
        labels:
            ref.read(applicationLabelsProvider).valueOrNull?.labels ?? const {},
      );
      if (message != null) {
        setState(() => refusal = message);
      } else if (applicationChangedMeanwhile(e)) {
        ref.invalidate(clApplicationsMasterProvider);
        toast(ApplicationViewStrings.changedMeanwhile, failed: true);
      } else {
        toast(ApplicationViewStrings.writeFailed, failed: true);
      }
    } finally {
      if (mounted) setState(() => running = null);
    }
  }

  /// Whether [step], one the state allows, may run now: Finalize is greyed
  /// out while the card lists texts missing or gaps naming no fact.
  bool mayRun(ApplicationStep step) =>
      step != ApplicationStep.save ||
      (widget.missing.isEmpty && widget.unknownFacts.isEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final template = widget.template;
    final busy = running != null;
    final refused = refusal;
    final draft = template.status == ApplicationStatus.draft;
    final title = applicationTitle(template);
    final status =
        ApplicationViewStrings.statusLabels[template.status.wireName] ??
        template.status.wireName;
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ApplicationViewSizes.smallGap,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ApplicationViewStrings.titleWithStatus(title, status),
                  key: const ValueKey('application.state.title'),
                  style: theme.textTheme.h4,
                ),
              ),
              ApplicationDownloadButton(
                key: const ValueKey('application.state.preview'),
                download: ApplicationPreview(template.id),
                pdfAction: widget.pdfAction,
                fileName: PdfAction.fileNameFor(title),
                label: ApplicationViewStrings.preview,
                icon: LucideIcons.eye,
                iconOnly: true,
              ),
              if (!draft)
                ApplicationDownloadButton(
                  key: const ValueKey('application.state.blankForm'),
                  download: ApplicationBlankForm(template.id),
                  pdfAction: widget.pdfAction,
                  fileName: PdfAction.fileNameFor(
                    ApplicationViewStrings.blankFormFileTitle(title),
                  ),
                  label: ApplicationViewStrings.blankForm,
                  iconOnly: true,
                ),
            ],
          ),
          if (template.status == ApplicationStatus.published)
            if (template.publishId case final String id)
              ApplicationPublishId(publishId: id),
          if (!draft)
            Text(
              ApplicationViewStrings.revertToEdit,
              style: theme.textTheme.muted,
            ),
          if (draft && widget.missing.isNotEmpty)
            ApplicationMissingTexts(missing: widget.missing),
          if (draft && widget.unknownFacts.isNotEmpty)
            ApplicationUnknownFacts(gaps: widget.unknownFacts),
          if (refused != null)
            Text(
              refused,
              key: const ValueKey('application.state.refusal'),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: ApplicationViewSizes.smallGap,
                  runSpacing: ApplicationViewSizes.smallGap,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final step in ApplicationStep.values)
                      if (step != ApplicationStep.delete &&
                          step.offeredIn(template.status))
                        ApplicationStepButton(
                          step: step,
                          loading: running == step,
                          enabled: mayRun(step),
                          onPressed: busy ? null : () => run(step),
                        ),
                  ],
                ),
              ),
              if (ApplicationStep.delete.offeredIn(template.status))
                Semantics(
                  button: true,
                  label: ApplicationStep.delete.label,
                  child: ShadIconButton.ghost(
                    key: const ValueKey('application.step.delete'),
                    enabled: !busy,
                    onPressed: () => run(ApplicationStep.delete),
                    icon: Icon(
                      LucideIcons.trash2,
                      color: theme.colorScheme.destructive,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
