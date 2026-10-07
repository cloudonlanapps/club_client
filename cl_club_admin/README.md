# cl_club_admin

Admin-only club views. Each takes `required UserPrivate currentUser` plus
navigation callbacks, asserts the role its screen gated on, and is mounted by
a screen in `cl_member_zone` at a route the `cl_club_app` router defines.

- **`InquiriesView`** (club_core#21) — the inbox of the public website's
  contact and interest forms: filter by kind and handled state, paged newest
  first; a row opens in a side sheet with the full message and `extra`,
  Mark handled / Mark open, and Delete (hard, confirmed: it is PII). Admin
  only; the sidebar's Admin section shows the open count beside Inquiries.

- **`SiteMediaView`** (club_core#19) — the public website's media slots
  (`SiteMediaSlot`, shared with `cl_club_website` through
  `cl_remote_store`): per slot, what fills it now, Upload (images, public
  on upload, through the shared image picker), Link existing (public
  media only) and Clear. Changes collect in a draft and Save writes the
  whole `site_media` map; a slot the server refuses as not public says so
  in place. Super-admin only, like the preference endpoint.

- **`ClubIdentityView`** (club_core#20) — the club's name, short name,
  inquiry email and public contact block (the `club_info` preference the
  website and the server's email branding and inquiry routing read), as
  one `ClubIdentityForm` (cl_club_forms). Translatable fields take a default and
  optional per-language texts; languages are added by code. Save writes
  the whole document in one call, over the master's read so keys the form
  does not edit survive; `club_identity_form_helpers.dart` is the form ↔
  SDK adapter. Super-admin only.

SDK access goes through `cl_remote_store` (`clInquiriesMasterProvider`,
`clUnhandledInquiryCountProvider`, `clSiteMediaMasterProvider`,
`clMediaLibraryProvider`, `clClubIdentityMasterProvider`). Widget tests
are in `test/`; the end-to-end flows are in
`cl_club_app/example/integration_test/`.
