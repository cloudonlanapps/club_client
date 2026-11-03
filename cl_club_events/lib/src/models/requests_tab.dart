/// The tabs of the Requests sheet, in display order (club_client#437).
enum RequestsTab {
  /// Leave for the session: pending to decide, approved to read.
  leave('Leave', 'No leave requests for this session.'),

  /// Members asking to join the event.
  enrollment('Enrollment', 'No enrollment requests.'),

  /// Members asking to leave the event.
  withdrawal('Withdrawal', 'No withdrawal requests.');

  const RequestsTab(this.label, this.emptyMessage);

  /// The tab's name, before its count.
  final String label;

  /// What the tab says when it has nothing to list.
  final String emptyMessage;

  /// The tab's label with [count] beside it, e.g. `Leave (2)`.
  String labelWith(int count) => '$label ($count)';
}
