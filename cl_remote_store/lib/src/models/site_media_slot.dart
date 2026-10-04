/// A visual the public website fills for itself, rather than one that
/// belongs to a row in the database (club_core#19).
///
/// The site names the purposes; the server stores `{ serverKey: mediaUuid }`
/// in its `site_media` preference and publishes each as a `MediaRef` in the
/// public club info. The website renders a slot (with a bundled default of
/// its own), and the admin screen sets it — both read this one list, so it
/// lives here rather than in either.
///
/// Per-page overrides (`page_hero.<page>`) can be added later without a
/// server change.
enum SiteMediaSlot {
  /// The landing hero's background. Image or video: the media record decides,
  /// not the slot.
  landingBackground(
    serverKey: 'landing_background',
    label: 'Landing background',
  ),

  /// The hero of every content page that has no image of its own.
  pageHeroDefault(
    serverKey: 'page_hero_default',
    label: 'Default page hero',
  ),

  /// The club mark in the website's navbar and footer, and the email banner
  /// logo (club_server#320, #321).
  logo(serverKey: 'logo', label: 'Logo');

  const SiteMediaSlot({required this.serverKey, required this.label});

  /// The key this slot has in the server's `site_media` map.
  final String serverKey;

  /// What an admin reads for the slot.
  final String label;

  /// The slot for [serverKey], or `null` for a key this list does not name.
  static SiteMediaSlot? fromServerKey(String serverKey) {
    for (final slot in values) {
      if (slot.serverKey == serverKey) return slot;
    }
    return null;
  }
}
