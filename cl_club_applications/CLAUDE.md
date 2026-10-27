# cl_club_applications

Printable applications (club_client#321, design
[`../docs/applications_design.md`](../docs/applications_design.md) §2–§4): an
admin writes an application template, moves it draft → saved → published, and
a member downloads their own form of a published one as a PDF, prints it,
affixes a passport-size photograph, signs it and hands it in. Use the design's
terms (application, template, fact, clause, age category, selection,
declaration, terms, notes, labels, layout).

Everything is capability-aware: each view and widget renders nothing unless
`applicationsProvider` is `true`. SDK access goes through `cl_remote_store`
(`clApplicationsMasterProvider`, its moves and PDF downloads,
`applicationLabelsProvider` and its `updateLabel`,
`applicationClausesProvider`, `clApplicationLibraryMasterProvider`); the forms are the SDK-free
`Application*Form`s of `cl_club_forms`.

## Public surface (barrel)

| Where | Widget | Constructor |
|---|---|---|
| `applications/mine` (Main, every member) | `MyApplicationsView` | `currentUser`, `pdfAction`, `onOpenProfile` |
| `applications` (Club Management, admin) | `ApplicationsView` | `currentUser`, `onOpen(int id)`, `onPickJsonFile` |
| `applications/:id` (admin) | `ApplicationView` | `currentUser`, `applicationId`, `onBack`, `onDeleted`, `pdfAction`, `onSaveFile` |
| profile (injected by the router) | `ProfileApplicationsSection` | `member`, `own`, `pdfAction` |
| Club details (injected by `ClubIdentityScreen`) | `ApplicationLibrarySection` | — |
| Club details, after the Library (injected by `ClubIdentityScreen`) | `ApplicationLabelsSection` | — |
| onboarding's waiting page (injected) | `PublishedApplicationsList` | `currentUser`, `pdfAction`, `onOpenProfile` |

Screens are `MyApplicationsScreen`, `ApplicationsScreen` and
`ApplicationScreen` in `cl_member_zone`;
the routes and the injections are `cl_club_app`'s `application_routes.dart`.

## The adapter

The forms speak the template's snake_case JSON with days as `YYYY-MM-DD`;
the SDK speaks camelCase with days as UTC-midnight milliseconds.
`ApplicationFormJson` translates both ways (a whole template survives the
round trip), and `ApplicationFormSubmit` sends each editor section's fields
alone (`update<Section>`), mapping the server's field names back to the
forms' ids for a schema refusal.

## Rules

- A member is offered only the published applications they are eligible
  for (club_client#380): `isEligibleFor` (`utils/application_eligibility.dart`)
  mirrors club_server's `application_rules.fits`, R11. No age categories:
  everyone; otherwise born on or after / on or before a category's days
  (each optional, inclusive) and of one of its genders (none = any). No date
  of birth fits no category, and `PublishedApplicationsList` asks for one.
  `PublishedApplicationsList` (Main, waiting page) and
  `ProfileApplicationsSection` both filter. Change the rule here only with
  the server's.

- The editor's heading card (`ApplicationStateCard`, club_client#398)
  opens with "<Title> (Draft | Saved | Published)", with Preview and, once
  finalized, Download blank form as icons at the right of that row. It
  shows the moves the state allows, no others: a draft Finalize (the save
  move), a saved one Publish and Revert to draft, a published one
  Unpublish; Delete is a bin icon at the bottom right (draft and saved),
  asking first. Finalize is greyed out, with no reason beside it, while
  the card lists what blocks it: **Missing:**
  (`ApplicationCompleteness.missingTexts`) and **Unknown facts:**
  (`ApplicationFactGaps.unknown`, `{gap}`s naming no fact,
  club_client#389), by place and language ("Selection 2 (Marathi): no
  fact named match_date"), each one heading in the error colour with
  smaller lines.
- A section's read view keeps the line of each fixed text of Languages and
  titles, and of the Declaration, while blank: an optional one shows
  nothing, a required one (title, footer line, declaration) **Required** in
  the error colour. A line's label is set larger than its value
  (club_client#398).
- A library text is inserted as written in every print language, gaps included: nothing is filled and no call is made
  (club_client#389). A fact prints wherever its `{name}` stands; the (?) on
  the Facts heading (`ApplicationFactsHelp`) says so, with one example per
  type.
- The club's library texts are managed in the **Library** card
  (`ApplicationLibrarySection`, exported) on Club details, after Profile
  options (club_client#399): `ClubIdentityScreen` (cl_member_zone) passes
  it to `ClubIdentityView` as `librarySection`, so cl_club_admin does not
  depend on this package. It renders nothing unless `applicationsProvider`
  is `true`; the Applications page lists templates only.
  Add text opens `ApplicationLibraryTextForm` in a dialog; each text's card
  edits it in place and deletes it after asking. The adapter is
  `ApplicationLibraryTextFormSubmit`. The server seeds its built-in clauses
  into the library once (club_server#133, club_client#396), so the card
  lists every text and each section's list offers the same texts, by
  name, with no built-in or club split.
- The club's languages are Profile options' languages (`{code, name}`,
  English always): they are the print languages a template may choose, and
  the languages the labels and library texts are shown and written in
  (club_client#396). Language names come from `languageNames`, the codes
  the server knows by name; another code shows as itself.
- The club's labels are managed in the **Labels** card
  (`ApplicationLabelsSection`, exported) on Club details, after the
  Library card (club_client#396), passed in as `labelsSection`: each label
  by its English text with its text in every club language, a blank one
  **Required** in the error colour, edited in place with
  `ApplicationLabelForm` (adapter `ApplicationLabelFormSubmit`, through
  `applicationLabelsProvider.updateLabel`). The heading card's Missing list
  names each club label lacking a print language that the template does
  not override ("Label: Full name — Hindi missing",
  `applicationLabelGaps`), and a refusal's `labels.<key>` entries name it
  the same way.
- A write refused for a language the club does not offer
  (`ApplicationLanguageNotOfferedException`) shows inline: on the heading
  card for Finalize, and in the form that sent it (a section, Create, a
  library text, a label); Import's toast names it
  (`applicationLanguageRefusal`).
- What the server refuses about the template on Finalize (incomplete, a
  gap naming no fact, does not fit, a language not offered, broken
  reference) shows inline on the heading card as "Finalize was refused: …"; a download refused
  for the member (not eligible, no identity document, not published) shows
  under its button. Anything else is a toast with a fixed message.
- A member's download of their own form (`ApplicationOwnForm`) first asks
  "Is your profile complete?" (`ProfileCompleteDialog`, club_client#340),
  listing the fields the form prints that are blank on the signed-in
  member's profile (`blankProfileFields`, read through
  `currentUserProvider`); with none blank it downloads without asking. Yes
  downloads, No calls the host's `onOpenProfile`, or only closes the
  dialog where there is none (the profile section, already on the profile).
  An admin's preview and a member's form fetched by an admin do not ask.
- The editor's heading card shows **Download blank form** as an icon
  beside Preview's (club_client#393, #398): the template printed blank, no
  member and no watermark (`ApplicationBlankForm`, `downloadBlankForm`).
  It is hidden on a draft and shown for a saved or published template; the
  PDF goes to the `PdfAction` as "<title> - blank form.pdf". A refusal
  (`APPLICATION_NOT_SAVED`, a template reverted meanwhile) shows under the
  button.
- A finalized (saved or published) template is carried to another server
  as a file (club_client#400). **Export JSON**, at the foot of the editor
  apart from the moves, writes its content alone (texts, facts, age
  categories, selections, terms, notes, label overrides; never its id,
  state, layout or dates) as `<title>.json`:
  `{"format": "club.application", "version": 1, "content": {…}}`
  (`ApplicationTemplateFile`), and hands it to the router's `onSaveFile`
  (the app's `saveFileBytes`). **Import JSON**, beside Create application,
  reads a file from the router's `onPickJsonFile` (the app's
  `pickJsonFile`; a bare content object is read too) and creates a **new
  draft** through `clApplicationsMasterProvider`, opened in the editor, so
  its dates and facts are checked before it is finalized there. A file
  that is not an exported application says "This file is not an exported
  application."; a refusal is a fixed toast.
