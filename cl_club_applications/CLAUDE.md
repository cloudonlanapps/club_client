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
`applicationLabelsProvider`, `applicationClausesProvider`); the forms are the
SDK-free `Application*Form`s of `cl_club_forms`.

## Public surface (barrel)

| Where | Widget | Constructor |
|---|---|---|
| `applications` | `ApplicationsView` | `currentUser`, `onOpen(int id)`, `pdfAction`, `onOpenProfile` |
| `applications/:id` (admin) | `ApplicationView` | `currentUser`, `applicationId`, `onBack`, `onDeleted`, `pdfAction` |
| profile (injected by the router) | `ProfileApplicationsSection` | `member`, `own`, `pdfAction` |
| onboarding's waiting page (injected) | `PublishedApplicationsList` | `currentUser`, `pdfAction`, `onOpenProfile` |

Screens are `ApplicationsScreen` and `ApplicationScreen` in `cl_member_zone`;
the routes and the injections are `cl_club_app`'s `application_routes.dart`.

## The adapter

The forms speak the template's snake_case JSON with days as `YYYY-MM-DD`;
the SDK speaks camelCase with days as UTC-midnight milliseconds.
`ApplicationFormJson` translates both ways (a whole template survives the
round trip), and `ApplicationFormSubmit` sends each editor section's fields
alone (`update<Section>`), mapping the server's field names back to the
forms' ids for a schema refusal.

## Rules

- Moves the state forbids are greyed out with their reason beside them; Save
  is also greyed out while `ApplicationCompleteness.missingTexts` lists
  texts, which the State card shows.
- What the server refuses about the template on Save (incomplete, does not
  fit, broken reference) shows inline on the State card; a download refused
  for the member (not eligible, no identity document, not published) shows
  under its button. Anything else is a toast with a fixed message.
- A member's download of their own form (`ApplicationOwnForm`) first asks
  "Is your profile complete?" (`ProfileCompleteDialog`, club_client#340):
  Yes downloads, No calls the host's `onOpenProfile`, or only closes the
  dialog where there is none (the profile section, already on the profile).
  An admin's preview and a member's form fetched by an admin do not ask.
