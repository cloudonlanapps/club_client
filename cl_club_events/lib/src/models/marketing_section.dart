/// The sections of an event's Marketing page (club_client#1). [basic] is
/// on the event and always shown; the rest are the extended block, shown
/// when the deployment runs the Event Marketing module.
enum MarketingSection {
  /// Short description, stamp, highlights and includes.
  basic,

  /// Duration, schedule and eligibility in words, deadline, places,
  /// urgency and contact number.
  details,

  /// The fee and the fee structure.
  fees,

  /// Packages.
  packages,

  /// Offers.
  offers,

  /// The club membership offered.
  membership,

  /// Facilities.
  facilities,
}
