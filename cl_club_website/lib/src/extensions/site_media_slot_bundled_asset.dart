import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaAsset, SiteMediaSlot;

export 'package:cl_remote_store/cl_remote_store.dart' show SiteMediaSlot;

/// The site's bundled default for each slot.
///
/// The slots live in `cl_remote_store` ([SiteMediaSlot]), shared with the
/// admin screen that sets them (club_core#19), and so does the admin's
/// upload for each (`clPublicSiteMediaProvider`). What stands in when there
/// is none — until the club info arrives, on a deployment that set nothing,
/// or when the server cannot answer — is the site's own, shipped with the
/// build, so a hero is never empty and never a broken image.
extension SiteMediaSlotBundledAsset on SiteMediaSlot {
  /// The asset shipped with the build: the initial source, and the permanent
  /// fallback for anything the server cannot answer.
  String get bundledAsset => switch (this) {
    SiteMediaSlot.landingBackground => 'assets/media/landing_background.webp',
    SiteMediaSlot.pageHeroDefault => 'assets/media/page_hero_default.webp',
    SiteMediaSlot.logo => 'assets/images/club_logo.png',
  };

  /// [bundledAsset] as the media filling this slot: an image, its own
  /// preview.
  SiteMediaAsset get bundledMedia => SiteMediaAsset(
    uri: bundledAsset,
    isVideo: false,
    previewUri: bundledAsset,
  );
}
