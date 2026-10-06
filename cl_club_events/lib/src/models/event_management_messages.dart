/// The labels, confirmations and toasts of the Event Management card's
/// Archive, Unarchive and Delete actions (club_client#36).
///
/// In the app the server's soft delete is called Archive; its hard delete
/// is Delete.
abstract final class EventManagementMessages {
  /// Title of the card.
  static const String title = 'Event Management';

  /// Button that renames the event.
  static const String rename = 'Rename';

  /// Button that archives the event.
  static const String archive = 'Archive';

  /// Button that restores an archived event.
  static const String unarchive = 'Unarchive';

  /// Button that removes an archived event for good.
  static const String delete = 'Delete';

  /// Title of the Archive confirmation.
  static const String archiveTitle = 'Archive event';

  /// Title of the Delete confirmation.
  static const String deleteTitle = 'Delete event';

  /// Toast after a rename.
  static const String renamed = 'Event renamed.';

  /// Toast after an archive.
  static const String archived = 'Event archived.';

  /// Toast after an unarchive.
  static const String unarchived = 'Event unarchived.';

  /// Toast after a delete.
  static const String deleted = 'Event deleted.';

  /// Toast when a rename fails with no more specific reason.
  static const String renameFailed =
      'Could not rename event. Please try again.';

  /// Toast when an archive fails with no more specific reason.
  static const String archiveFailed =
      'Could not archive event. Please try again.';

  /// Toast when an unarchive fails with no more specific reason.
  static const String unarchiveFailed =
      'Could not unarchive event. Please try again.';

  /// Toast when a delete fails with no more specific reason.
  static const String deleteFailed =
      'Could not delete event. Please try again.';

  /// Toast when the server refuses an unarchive because the event's venue
  /// is deleted (`VENUE_IS_DELETED`).
  static const String venueIsDeleted =
      'The venue of this event is deleted. Restore the venue first, then '
      'unarchive the event.';

  /// Toast when the server refuses a delete because the event is not
  /// archived (`HARD_DELETE_NEEDS_SOFT_DELETE`).
  static const String deleteNeedsArchive =
      'Only an archived event can be deleted. Archive it first.';

  /// Toast when the server refuses an unarchive because the event is not
  /// archived (`NOTHING_TO_RESTORE`).
  static const String notArchived = 'This event is not archived.';

  /// Line at the top of an archived event's page.
  static const String archivedNotice =
      'This event is archived. It is not shown in the lists, the calendar '
      'or the public site, and cannot be edited until it is unarchived.';

  /// Body of the Archive confirmation for the event titled [eventTitle].
  static String archiveConfirm(String eventTitle) =>
      'Archive "$eventTitle"? It leaves the lists, the calendar and the '
      'public site, and its enrolled members are notified. An admin can '
      'unarchive it later.';

  /// Body of the Delete confirmation for the event titled [eventTitle].
  static String deleteConfirm(String eventTitle) =>
      'Delete "$eventTitle"? This permanently removes the event with its '
      'enrolments and attendance. It cannot be undone.';
}
