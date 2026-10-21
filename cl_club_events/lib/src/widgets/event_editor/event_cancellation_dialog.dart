import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventCancellationForm,
        EventCancellationFormState,
        EventCancellationSession;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClOccurrencesKey, clEventsMasterProvider, clOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show SavingDialogCloseIcon, SavingDialogScope;

import '../../models/event_cancellation_form_helpers.dart';
import '../../models/event_cancellation_messages.dart';
import '../../models/stale_version_message.dart';
import '../../utils/event_cancellation_error.dart';

/// What an [EventCancellationDialog] cancels.
enum EventCancellationKind {
  /// A camp, from a session picked in the dialog (the event page).
  camp,

  /// A one-off, called off (the event page or its occurrence card).
  oneOff,

  /// One session of a camp or a programme (its occurrence card).
  occurrence,

  /// A camp, from the session whose card opened the dialog.
  seriesFromOccurrence,
}

/// Dialog that cancels a camp from a chosen upcoming session, calls a
/// one-off off (club_client#40), cancels one session, or cancels a camp
/// from one session (club_client#213), with a reason.
///
/// Hosts the SDK-free [EventCancellationForm]. For a camp from the event
/// page it offers the camp's upcoming sessions, the next one preselected;
/// otherwise the reason alone. Its title, description and confirm label
/// are those of the action that opened it, and the description says how
/// the change is taken back. Saves while it is open, and pops `true` once
/// the server has accepted it; a blank reason keeps it open on the field's
/// message, with nothing sent. A refusal shows in the form: on the session
/// picked when it is about that session, else as a line under the fields.
/// A stale version closes the dialog with a toast, since the event has
/// been reloaded.
class EventCancellationDialog extends ConsumerStatefulWidget {
  /// Cancels the camp [event] from a session picked in the dialog, or calls
  /// the one-off [event] off ([occurrenceVersion] given).
  const EventCancellationDialog({
    required this.event,
    this.occurrenceVersion,
    super.key,
  }) : occurrence = null,
       wholeSeries = false;

  /// Cancels [occurrence] of [event] alone (Cancel this occurrence).
  const EventCancellationDialog.occurrence({
    required this.event,
    required Occurrence this.occurrence,
    super.key,
  }) : occurrenceVersion = null,
       wholeSeries = false;

  /// Cancels the camp [event] from [occurrence] on (Cancel entire series).
  const EventCancellationDialog.seriesFrom({
    required this.event,
    required Occurrence this.occurrence,
    super.key,
  }) : occurrenceVersion = null,
       wholeSeries = true;

  /// The event to cancel or call off, or whose session to cancel.
  final Event event;

  /// For a one-off: the version of its single occurrence as loaded, which
  /// the server's drop asks for. `null` otherwise.
  final int? occurrenceVersion;

  /// The session the dialog was opened from, for [EventCancellationKind]
  /// `occurrence` and `seriesFromOccurrence`.
  final Occurrence? occurrence;

  /// Whether the camp is cancelled from [occurrence] on, not [occurrence]
  /// alone.
  final bool wholeSeries;

  /// What the dialog cancels.
  EventCancellationKind get kind {
    if (occurrence != null) {
      return wholeSeries
          ? EventCancellationKind.seriesFromOccurrence
          : EventCancellationKind.occurrence;
    }
    return occurrenceVersion == null
        ? EventCancellationKind.camp
        : EventCancellationKind.oneOff;
  }

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

  EventCancellationKind get kind => widget.kind;

  /// Whether the dialog offers the camp's sessions to cancel from.
  bool get isCamp => kind == EventCancellationKind.camp;

  /// The dialog's title.
  String get title => switch (kind) {
    EventCancellationKind.camp => EventCancellationMessages.cancelCamp,
    EventCancellationKind.oneOff => EventCancellationMessages.callOff,
    EventCancellationKind.occurrence =>
      EventCancellationMessages.cancelOccurrenceTitle,
    EventCancellationKind.seriesFromOccurrence =>
      EventCancellationMessages.cancelSeriesTitle,
  };

  /// What the change does, and how it is taken back.
  String get description => switch (kind) {
    EventCancellationKind.camp =>
      EventCancellationMessages.cancelCampDescription,
    EventCancellationKind.oneOff =>
      EventCancellationMessages.callOffDescription,
    EventCancellationKind.occurrence =>
      EventCancellationMessages.cancelOccurrenceDescription,
    EventCancellationKind.seriesFromOccurrence =>
      EventCancellationMessages.cancelSeriesDescription,
  };

  /// The confirm button's label.
  String get actionLabel => switch (kind) {
    EventCancellationKind.camp => EventCancellationMessages.cancelCamp,
    EventCancellationKind.oneOff => EventCancellationMessages.callOff,
    EventCancellationKind.occurrence =>
      EventCancellationMessages.cancelOccurrence,
    EventCancellationKind.seriesFromOccurrence =>
      EventCancellationMessages.cancelSeries,
  };

  /// What the action's button reads while the server is asked.
  String get inFlightLabel => kind == EventCancellationKind.oneOff
      ? EventCancellationMessages.callingOff
      : EventCancellationMessages.cancelling;

  /// The message when the change fails with no better one.
  String get failedMessage => switch (kind) {
    EventCancellationKind.camp || EventCancellationKind.seriesFromOccurrence =>
      EventCancellationMessages.cancelCampFailed,
    EventCancellationKind.oneOff => EventCancellationMessages.callOffFailed,
    EventCancellationKind.occurrence =>
      EventCancellationMessages.cancelOccurrenceFailed,
  };

  /// Sends the change the form's [values] describe.
  Future<void> send(Map<String, dynamic> values) {
    final notifier = ref.read(clEventsMasterProvider.notifier);
    final event = widget.event;
    final occurrence = widget.occurrence;
    return switch (kind) {
      EventCancellationKind.camp => EventCancellationFormSubmit.cancelCamp(
        eventId: event.id,
        eventVersion: event.version,
        values: values,
        notifier: notifier,
      ),
      EventCancellationKind.oneOff => EventCancellationFormSubmit.callOff(
        eventId: event.id,
        occurrenceVersion: widget.occurrenceVersion!,
        values: values,
        notifier: notifier,
      ),
      EventCancellationKind.occurrence =>
        EventCancellationFormSubmit.cancelOccurrence(
          occurrence: occurrence!,
          values: values,
          notifier: notifier,
        ),
      // No version: the master sends the one it holds for the camp this
      // session belongs to (club_client#123).
      EventCancellationKind.seriesFromOccurrence =>
        EventCancellationFormSubmit.cancelCampFrom(
          eventId: event.id,
          fromUtc: occurrence!.originalStartTimeUtc,
          values: values,
          notifier: notifier,
        ),
    };
  }

  /// The occurrence feed range holding the camp's remaining sessions.
  ClOccurrencesKey get sessionsRange =>
      (from: openedAt, to: lastOccurrenceEndUtc(widget.event));

  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    setState(() => isSubmitting = true);
    try {
      await send(values);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e, st) {
      if (!mounted) return;
      final fallback = failedMessage;
      final aboutSession = kind == EventCancellationKind.occurrence;
      final message = e is StaleVersionException && aboutSession
          ? staleVersionMessage(e, subject: 'This session')
          : eventCancellationErrorMessage(
              e,
              stackTrace: st,
              fallback: fallback,
              aboutSession: aboutSession,
            );
      if (e is StaleVersionException) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(message)),
        );
        Navigator.of(context).pop(false);
        return;
      }
      setState(() => isSubmitting = false);
      final refusal = eventCancellationRefusal(
        e,
        isCamp: isCamp,
        message: message,
        fallback: fallback,
      );
      // A failure that is not about the cancellation is a toast; the
      // dialog stays, on again, for another try.
      if (refusal == null) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(message)),
        );
      } else {
        formKey.currentState?.showErrors(
          fieldErrors: refusal.fieldErrors,
          formError: refusal.formError,
        );
      }
    }
  }

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

    return SavingDialogScope(
      saving: isSubmitting,
      child: ShadDialog(
        closeIcon: SavingDialogCloseIcon(saving: isSubmitting),
        title: Text(title),
        description: Text(description),
        actions: [
          ShadButton.outline(
            onPressed: isSubmitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text(EventCancellationMessages.back),
          ),
          ShadButton.destructive(
            onPressed: canSubmit ? submit : null,
            child: Text(isSubmitting ? inFlightLabel : actionLabel),
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
      ),
    );
  }
}
