/// An action the occurrence card offers the event's staff
/// (`adminOccurrenceActionsFor`).
enum AdminOccurrenceAction {
  /// Open the occurrence's attendance register.
  attendance,

  /// Move the occurrence, change its length or its venue.
  reschedule,

  /// Cancel this occurrence alone.
  cancelOccurrence,

  /// Cancel the camp from this occurrence on.
  cancelSeries,

  /// End the programme from this occurrence on (terminate, or move its end).
  endProgramme,

  /// Call off a one-off: cancel its single occurrence.
  callOff,

  /// Decide the event's pending enrollment requests.
  manageRequests,

  /// Restore a cancelled occurrence.
  undoCancel,
}
