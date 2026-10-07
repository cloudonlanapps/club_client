import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventCancellationForm,
        EventCancellationFormFields,
        EventCancellationFormState,
        EventCancellationSession;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClOccurrencesKey, clEventsMasterProvider, clOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_cancellation_form_helpers.dart';
import '../../models/event_cancellation_messages.dart';
import '../../utils/event_cancellation_error.dart';

/// Dialog that cancels a camp from a chosen upcoming session, or calls a
/// one-off off, with a reason (club_client#40).
///
/// Hosts the SDK-free [EventCancellationForm]. For a camp it offers the
/// camp's upcoming sessions, the next one preselected; for a one-off
/// ([occurrenceVersion] given) the reason alone. Pops `true` once the
/// server has accepted it. A refusal shows in the form: on the session
/// picked when it is about that session, else as a line under the fields.
/// A stale version closes the dialog with a toast, since the event has
/// been reloaded.
class EventCancellationDialog extends ConsumerStatefulWidget {
  const EventCancellationDialog({
    required this.event,
    this.occurrenceVersion,
    super.key,
  });

  /// The camp or one-off to call off.
  final Event event;

  /// For a one-off: the version of its single occurrence as loaded, which
  /// the server's drop asks for. `null` for a camp.
  final int? occurrenceVersion;

  @override
  ConsumerState<EventCancellationDialog> createState() =>
      EventCancellationDialogState();
}

class EventCancellationDialogState
    extends ConsumerState<EventCancellationDialog> {
  final formKey = GlobalKey<EventCancellationFormState>();
  bool isSubmitting = false;

  /// When the dialog opened; the camp's sessions are read from here on.
  final DateTime openedAt = DateTime.now().toUtc();

  bool get isCamp => widget.event.type == EventType.camp;

  String get actionLabel => isCamp
      ? EventCancellationMessages.cancelCamp
      : EventCancellationMessages.callOff;

  /// The occurrence feed range holding the camp's remaining sessions.
  ClOccurrencesKey get sessionsRange =>
      (from: openedAt, to: lastOccurrenceEndUtc(widget.event));

  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    setState(() => isSubmitting = true);
    final notifier = ref.read(clEventsMasterProvider.notifier);
    final version = widget.occurrenceVersion;
    try {
      if (version == null) {
        await EventCancellationFormSubmit.cancelCamp(
          eventId: widget.event.id,
          values: values,
          notifier: notifier,
        );
      } else {
        await EventCancellationFormSubmit.callOff(
          eventId: widget.event.id,
          occurrenceVersion: version,
          values: values,
          notifier: notifier,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e, st) {
      if (!mounted) return;
      final message = eventCancellationErrorMessage(
        e,
        stackTrace: st,
        fallback: isCamp
            ? EventCancellationMessages.cancelCampFailed
            : EventCancellationMessages.callOffFailed,
      );
      if (e is StaleVersionException) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(message)),
        );
        Navigator.of(context).pop(false);
        return;
      }
      setState(() => isSubmitting = false);
      if (isCamp && isAboutSession(e)) {
        formKey.currentState?.showErrors(
          fieldErrors: {EventCancellationFormFields.fromSessionId: message},
        );
      } else {
        formKey.currentState?.showErrors(formError: message);
      }
    }
  }

  /// Whether the refusal [error] is about the session the cancellation
  /// starts from: too close, already past, or no longer a session.
  bool isAboutSession(Object error) =>
      error is ServerException &&
      error is! StaleVersionException &&
      (error.code == SdkErrorCode.cancellationLeadTimeViolated ||
          error.code == SdkErrorCode.effectiveTimeInPast ||
          error.code == SdkErrorCode.effectiveTimeNotSessionBoundary);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final sessions = isCamp
        ? ref
              .watch(clOccurrencesProvider(sessionsRange))
              .whenData(
                (occurrences) => buildEventCancellationSessions(
                  occurrences,
                  eventId: widget.event.id,
                  now: openedAt,
                ),
              )
        : const AsyncData(<EventCancellationSession>[]);
    final offered = sessions.valueOrNull;
    final notice = sessions.when(
      loading: () => EventCancellationMessages.loadingSessions,
      error: (_, _) => EventCancellationMessages.sessionsFailed,
      data: (list) => isCamp && list.isEmpty
          ? EventCancellationMessages.noUpcomingSession
          : null,
    );
    final canSubmit = !isSubmitting && offered != null && notice == null;

    return ShadDialog(
      title: Text(actionLabel),
      description: Text(
        isCamp
            ? EventCancellationMessages.cancelCampDescription
            : EventCancellationMessages.callOffDescription,
      ),
      actions: [
        ShadButton.outline(
          onPressed: isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text(EventCancellationMessages.back),
        ),
        ShadButton.destructive(
          onPressed: canSubmit ? submit : null,
          child: Text(actionLabel),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: notice != null
            ? Text(notice, style: theme.textTheme.muted)
            : EventCancellationForm(
                key: formKey,
                sessions: offered ?? const [],
                enabled: !isSubmitting,
              ),
      ),
    );
  }
}
