/// The lengths and counts the server accepts in an event's marketing
/// (club_server#409, #410), checked by the forms before a save.
abstract final class EventMarketingLimits {
  /// The short description a card shows under the title.
  static const int shortDescription = 300;

  /// The stamp (badge text).
  static const int stamp = 60;

  /// One highlight or included item.
  static const int bullet = 200;

  /// Highlights, included items, and the rows of any extended list.
  static const int listRows = 20;

  /// A free text of the extended block.
  static const int text = 500;

  /// A name or title in the extended block, and the urgency line.
  static const int name = 200;

  /// The contact number.
  static const int contactNumber = 32;

  /// A fee's period.
  static const int period = 50;

  /// A facility's icon name.
  static const int iconName = 50;
}
