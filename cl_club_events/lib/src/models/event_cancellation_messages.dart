/// The labels, dialogs and toasts of calling an event off and taking that
/// back, from the Event Management card (club_client#40) and the occurrence
/// card (club_client#213).
///
/// A camp is cancelled from a session onward and the cancellation undone; a
/// one-off is called off and reinstated; one session of a camp or a
/// programme is cancelled and restored with Undo Cancel. Each dialog says
/// how its change is taken back: none of them is final.
abstract final class EventCancellationMessages {
  /// Button that cancels a camp.
  static const String cancelCamp = 'Cancel camp';

  /// What [cancelCamp] reads while the camp is being cancelled.
  static const String cancelling = 'Cancelling…';

  /// Button that undoes a camp's cancellation.
  static const String undoCancel = 'Undo cancel';

  /// Button that calls a one-off off.
  static const String callOff = 'Call off';

  /// What [callOff] reads while the one-off is being called off.
  static const String callingOff = 'Calling off…';

  /// Button that reinstates a called-off one-off.
  static const String reinstate = 'Reinstate';

  /// Button that closes a dialog without doing anything.
  static const String back = 'Back';

  /// Title of the dialog that cancels one session, as the occurrence card
  /// labels the action.
  static const String cancelOccurrenceTitle = 'Cancel this occurrence';

  /// Button that cancels one session.
  static const String cancelOccurrence = 'Cancel occurrence';

  /// Title of the dialog that cancels a camp from one of its sessions, as
  /// the occurrence card labels the action.
  static const String cancelSeriesTitle = 'Cancel entire series';

  /// Button that cancels a camp from one of its sessions.
  static const String cancelSeries = 'Cancel series';

  /// Title of the Undo cancel confirmation.
  static const String undoCancelTitle = 'Undo cancellation';

  /// Title of the Reinstate confirmation.
  static const String reinstateTitle = 'Reinstate event';

  /// Body of the Cancel camp dialog.
  static const String cancelCampDescription =
      'The camp is cancelled from the chosen session onward; sessions '
      'before it still run. Enrolled members are notified, with the reason. '
      'You can take it back later with Undo cancel.';

  /// Body of the Call off dialog.
  static const String callOffDescription =
      'The event is called off. Enrolled members are notified, with the '
      'reason. You can reinstate it until it starts.';

  /// Body of the dialog that cancels one session.
  static const String cancelOccurrenceDescription =
      'This session is cancelled. Enrolled members are notified, with the '
      'reason. You can restore it later with Undo Cancel.';

  /// Body of the dialog that cancels a camp from one of its sessions.
  static const String cancelSeriesDescription =
      'The camp is cancelled from this session onward; sessions before it '
      'still run. Enrolled members are notified, with the reason. You can '
      'take it back later with Undo cancel on the event page.';

  /// Shown in the Cancel camp dialog while the camp's sessions load.
  static const String loadingSessions = 'Loading the sessions…';

  /// Shown in the Cancel camp dialog when the sessions cannot be read.
  static const String sessionsFailed =
      'Could not load the sessions of this camp. Please try again.';

  /// Shown in the Cancel camp dialog when no session is far enough ahead.
  static const String noUpcomingSession =
      'This camp has no session left to cancel from: a cancellation needs '
      "at least 30 minutes' notice.";

  /// Toast after a camp is cancelled.
  static const String campCancelled = 'Camp cancelled.';

  /// Toast after one session is cancelled.
  static const String occurrenceCancelled = 'Session cancelled.';

  /// Toast after a camp's cancellation is undone.
  static const String cancelUndone = 'Cancellation undone.';

  /// Toast after a one-off is called off.
  static const String calledOff = 'Event called off.';

  /// Toast after a one-off is reinstated.
  static const String reinstated = 'Event reinstated.';

  /// Fallback when cancelling a camp fails.
  static const String cancelCampFailed =
      'Could not cancel the camp. Please try again.';

  /// Fallback when cancelling one session fails.
  static const String cancelOccurrenceFailed =
      'Could not cancel the session. Please try again.';

  /// Fallback when undoing a cancellation fails.
  static const String undoCancelFailed =
      'Could not undo the cancellation. Please try again.';

  /// Fallback when calling a one-off off fails.
  static const String callOffFailed =
      'Could not call off the event. Please try again.';

  /// Fallback when reinstating a one-off fails.
  static const String reinstateFailed =
      'Could not reinstate the event. Please try again.';

  /// `CANCELLATION_LEAD_TIME_VIOLATED`.
  static const String tooClose =
      "It is too close to the start: this needs at least 30 minutes' notice.";

  /// `EFFECTIVE_TIME_IN_PAST`.
  static const String sessionInPast =
      'That session has already started. Choose a later one.';

  /// `EFFECTIVE_TIME_NOT_SESSION_BOUNDARY`.
  static const String notASession =
      'That is no longer a session of this camp. Close this and try again.';

  /// `EVENT_ALREADY_CANCELLED`.
  static const String alreadyCancelled = 'This camp is already cancelled.';

  /// `EVENT_NOT_CANCELLED`.
  static const String notCancelled = 'This camp is not cancelled.';

  /// `PAST_OCCURRENCE`.
  static const String alreadyHappened =
      'This event has already started and cannot be called off.';

  /// `CANCELLED_OCCURRENCE`.
  static const String alreadyCalledOff = 'This event is already called off.';

  /// `PAST_OCCURRENCE` on one session's cancel.
  static const String sessionAlreadyStarted =
      'This session has already started and cannot be cancelled.';

  /// `CANCELLED_OCCURRENCE` on one session's cancel.
  static const String sessionAlreadyCancelled =
      'This session is already cancelled.';

  /// `INVALID_STATE` on a reinstate.
  static const String cannotReinstate =
      'This event has started, or is no longer called off, so it cannot be '
      'reinstated.';

  /// `INVALID_EVENT_TYPE`.
  static const String wrongEventType =
      'This action is not available for this type of event.';

  /// Body of the Undo cancel confirmation for the camp titled [eventTitle].
  static String undoCancelConfirm(String eventTitle) =>
      'Undo the cancellation of "$eventTitle"? Its cancelled sessions are '
      'back on.';

  /// Body of the Reinstate confirmation for the one-off titled [eventTitle].
  static String reinstateConfirm(String eventTitle) =>
      'Reinstate "$eventTitle"? It takes place as scheduled.';
}
