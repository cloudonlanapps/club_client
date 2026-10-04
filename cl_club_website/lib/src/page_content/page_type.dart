/// The site's content pages, each with its own block of copy.
///
/// These used to name a JSON file under `/static/pages/`; the copy is in the
/// site's ARB now, and `SiteCopy.pageData` maps a value to it.
enum PageType {
  /// Learning Camps page (events/camps).
  learningCamps,

  /// Training Sessions page (programs).
  trainingSessions,

  /// Club Events page (one-off events).
  clubEvents,

  /// Ice Masters page (coaches).
  iceMasters,

  /// The Rinks page (venues/locations).
  theRinks,

  /// The Club page (about).
  theClub,

  /// Contact Us page.
  contactUs,
}
