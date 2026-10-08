import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationsMasterProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show EvaluationStartForm, EvaluationStartFormState;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_start_form_submit.dart';
import '../utils/evaluation_error_message.dart';
import '../utils/start_review_choices.dart';

/// Starts a review (design 4.3): asks for the template, the member, the
/// event or *General*, and an optional period, creates the draft and
/// resolves to its id — or `null` when cancelled, or when the server does
/// not run evaluations.
///
/// The caller fixes what its context already says: a member's profile the
/// member ([username]); an enrolment row the member and the event
/// ([eventId]); a template's *Start* the template ([templateId]). A refusal
/// (e.g. `NOT_ELIGIBLE`) shows inline, in the form, and the dialog stays
/// open. While the draft is created the form and both buttons are off.
Future<int?> showStartReviewDialog({
  required BuildContext context,
  required UserPrivate currentUser,
  int? templateId,
  String? username,
  int? eventId,
}) async {
  final on = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(evaluationsProvider);
  if (on != true) return null;
  return showShadDialog<int>(
    context: context,
    builder: (_) => StartReviewDialog(
      currentUser: currentUser,
      templateId: templateId,
      username: username,
      eventId: eventId,
    ),
  );
}

/// The start-review dialog; see [showStartReviewDialog].
class StartReviewDialog extends ConsumerStatefulWidget {
  /// A dialog for [currentUser], a coach.
  const StartReviewDialog({
    required this.currentUser,
    this.templateId,
    this.username,
    this.eventId,
    super.key,
  });

  /// The coach starting the review.
  final UserPrivate currentUser;

  /// The template, when fixed.
  final int? templateId;

  /// The member, when fixed.
  final String? username;

  /// The event, when fixed.
  final int? eventId;

  @override
  ConsumerState<StartReviewDialog> createState() => StartReviewDialogState();
}

/// State of [StartReviewDialog]: the form and the create in flight.
class StartReviewDialogState extends ConsumerState<StartReviewDialog> {
  /// The start form.
  final GlobalKey<EvaluationStartFormState> formKey =
      GlobalKey<EvaluationStartFormState>();

  /// Whether the draft is being created.
  bool creating = false;

  /// Validates the form and creates the draft; pops with its id. A refusal
  /// shows in the form, said for people.
  Future<void> start() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    setState(() => creating = true);
    try {
      final created = await EvaluationStartFormSubmit.create(
        values: values,
        notifier: ref.read(clEvaluationsMasterProvider.notifier),
      );
      if (mounted) Navigator.of(context).pop(created.id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => creating = false);
      formKey.currentState?.showErrors(formError: EvaluationErrorMessage.of(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final options = StartReviewChoices.read(
      ref,
      coach: w.currentUser,
      templateId: w.templateId,
      username: w.username,
      eventId: w.eventId,
    );
    return ShadDialog(
      title: const Text(EvaluationViewStrings.startReview),
      constraints: const BoxConstraints(
        maxWidth: EvaluationViewSizes.dialogWidth,
      ),
      actions: [
        ShadButton.outline(
          onPressed: creating ? null : () => Navigator.of(context).pop(),
          child: const Text(EvaluationViewStrings.cancel),
        ),
        ShadButton(
          enabled: !creating,
          onPressed: start,
          child: const Text(EvaluationViewStrings.start),
        ),
      ],
      child: EvaluationStartForm(
        key: formKey,
        templates: options.templates,
        members: options.members,
        events: options.events,
        eventsByMember: options.eventsByMember,
        fixedTemplate: options.fixedTemplate,
        fixedMember: options.fixedMember,
        fixedEvent: options.fixedEvent,
        enabled: !creating,
      ),
    );
  }
}
