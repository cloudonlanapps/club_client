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

- **`ClubIdentityView`** (club_core#20, club_client#58) — the club's name,
  short name, inquiry email and public contact block (the `club_info`
  preference the website and the server's email branding and inquiry
  routing read), in three section cards: **Club** (`ClubDetailsCard`),
  **Contact** (`ClubContactCard`) and **Address** (`ClubAddressCard`).
  Each is an `EditableSectionCard` that shows the values that are set and
  edits them in place with its own form (`ClubDetailsForm`,
  `ClubContactForm`, `ClubAddressForm`, cl_club_forms) and its own Save.
  Translatable fields take a default and a text for each language
  offered: those the stored values already use, plus those added in this
  visit through a fourth card, **Translations** (`ClubTranslationsCard`,
  hosting `ClubLanguageForm` and its Add language button). Adding a
  language stores nothing; a translation is saved with its section. The server replaces the document whole on
  every write, so a section is saved as the master's read with that
  section's fields replaced (`ClubIdentityFormSubmit.updateClub` /
  `updateContact` / `updateAddress` in `club_identity_form_helpers.dart`,
  the form ↔ SDK adapter): the other sections, and keys no form edits,
  survive. Super-admin only.

SDK access goes through `cl_remote_store` (`clInquiriesMasterProvider`,
`clUnhandledInquiryCountProvider`, `clSiteMediaMasterProvider`,
`clMediaLibraryProvider`, `clClubIdentityMasterProvider`). Widget tests
are in `test/`; the end-to-end flows are in
`cl_club_app/example/integration_test/`.
