import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationStatus, ApplicationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog, PdfAction;

import '../constants/application_fact_strings.dart';
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

/// The **State** card of the application editor (club_client#321): the
/// template's state and stored layout, a published template's publish ID
/// (club_client#339), the moves Save, Publish, Unpublish,
/// Revert and Delete, and Preview.
///
/// A move the state forbids is greyed out up front with its reason beside
/// it; so is Save while the client's check finds texts [missing], or
/// `{gap}`s naming no fact ([unknownFacts], club_client#389), which it
/// lists. What the server refuses about the template on Save shows inline
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

  /// What the downloaded preview is handed to: shared, saved or opened.
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
      final message = applicationSaveRefusal(e);
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

  /// Why [step] is greyed out now, or null when it may run.
  String? reasonFor(ApplicationStep step) {
    final blocked = step.blockedBy(widget.template.status);
    if (blocked != null) return blocked;
    if (step == ApplicationStep.save && widget.missing.isNotEmpty) {
      return ApplicationViewStrings.textsMissing(widget.missing.length);
    }
    if (step == ApplicationStep.save && widget.unknownFacts.isNotEmpty) {
      return ApplicationFactStrings.unknownCount(widget.unknownFacts.length);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final template = widget.template;
    final busy = running != null;
    final layout = template.layout;
    final refused = refusal;
    final draft = template.status == ApplicationStatus.draft;
    return ShadCard(
      title: Text(ApplicationViewStrings.stateTitle, style: theme.textTheme.h4),
      child: Padding(
        padding: const EdgeInsets.only(top: ApplicationViewSizes.smallGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ApplicationViewSizes.smallGap,
          children: [
            Text(
              ApplicationViewStrings.statusLabels[template.status.wireName] ??
                  template.status.wireName,
              style: theme.textTheme.large,
            ),
            Text(
              layout == null
                  ? ApplicationViewStrings.noLayout
                  : ApplicationViewStrings.layout(layout.name),
              style: theme.textTheme.muted,
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
            Wrap(
              spacing: ApplicationViewSizes.smallGap,
              runSpacing: ApplicationViewSizes.smallGap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final step in ApplicationStep.values)
                  ApplicationStepButton(
                    step: step,
                    loading: running == step,
                    reason: reasonFor(step),
                    onPressed: busy ? null : () => run(step),
                  ),
                ApplicationDownloadButton(
                  download: ApplicationPreview(template.id),
                  pdfAction: widget.pdfAction,
                  fileName: PdfAction.fileNameFor(applicationTitle(template)),
                  label: ApplicationViewStrings.preview,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
