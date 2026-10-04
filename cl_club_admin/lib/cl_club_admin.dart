/// Admin-only club views, mounted by screens in `cl_member_zone`.
///
/// Each view takes `required UserPrivate currentUser` plus navigation
/// callbacks and asserts the role its screen gated on. SDK access goes
/// through the master providers in `cl_remote_store`.
library;

// Views
export 'src/views/club_identity_view.dart' show ClubIdentityView;
export 'src/views/inquiries_view.dart' show InquiriesView;
export 'src/views/site_media_view.dart' show SiteMediaView;
