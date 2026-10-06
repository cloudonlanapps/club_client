/// Keys of a notification payload's `data`, as the server writes them.
///
/// Covers the types added since the server's 0.5 release (club_core#32);
/// the older registry rows still spell their keys inline.
abstract final class NotificationPayloadKey {
  /// The event's id (event, enrollment and credit families).
  static const eventId = 'eventId';

  /// The event's title.
  static const eventTitle = 'eventTitle';

  /// Free-text reason an admin gave for a change.
  static const reason = 'reason';

  /// A programme's cutoff, UTC epoch ms; `null` on `event.extended` when
  /// the cutoff was cleared.
  static const cutoffTimeUtc = 'cutoffTimeUtc';

  /// An evaluation's id.
  static const evaluationId = 'evaluationId';

  /// The coach who owns a published evaluation.
  static const owner = 'owner';

  /// The member an evaluation is about.
  static const createdFor = 'createdFor';

  /// The previous owner of a transferred evaluation.
  static const fromOwner = 'fromOwner';

  /// An inquiry's kind wire name (`InquiryKind.wireName`).
  static const kind = 'kind';

  /// The name the inquirer gave.
  static const name = 'name';

  /// A group's id (`group.member_ineligible`).
  static const groupId = 'groupId';

  /// A group's name.
  static const groupName = 'groupName';

  /// The username of a group member, or of an enrolled member
  /// (`enrollment.member_ineligible`).
  static const membername = 'membername';
}
