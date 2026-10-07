# cl_club_evaluation

Member evaluations (club_core#173): the connected views over the
evaluation masters in `cl_remote_store` and the SDK-free evaluation forms in
`ui_lib`. The spec is [`../docs/evaluations_design.md`](../docs/evaluations_design.md)
§1, §3.7 and §4; use its terms (evaluation, evaluation template, item,
question, section, answer, coach note, evidence) — never "survey". A member
reads **reviews**; staff read **evaluations** and **templates**.

Everything is capability-aware: a view renders nothing, and
`showStartReviewDialog` resolves to `null`, unless `evaluationsProvider` is
`true`.

## Public surface (barrel)

Views only, plus the start dialog. Screens (`cl_member_zone`), routes
(`cl_club_app`), sidebar entries and the *Add Review* buttons
(`cl_club_members`, `cl_club_events`) are wired in #174.

| Route (design 4.2) | View | Constructor |
|---|---|---|
| `reviews/mine` | `MyReviewsView` | `currentUser`, `onOpen(int id)` |
| `reviews/mine/:id` | `EvaluationReadView` | `currentUser`, `username`, `evaluationId`, `onBack`, `onOpenPdfBytes(Uint8List bytes)` |
| `reviews` (coach) | `CoachReviewsView` | `currentUser`, `onOpenEvaluation(int id)`, `onOpenTemplates()` (**Manage Templates**, every coach) |
| `reviews` (admin, not coach), `reviews/templates` | `TemplateLibraryView` | `currentUser`, `onOpenTemplate(int id)`, `onCreateTemplate()`, `onDuplicateTemplate(int id)` |
| `reviews/templates/new` (`?copy=<id>` to duplicate) | `TemplateCreateView` | `currentUser`, `onCreated(int id)`, `onCancel()`, `copyOfTemplateId?` |
| `reviews/templates/:id` | `TemplateDetailView` | `currentUser`, `templateId`, `onBack` (also after Delete), `onDuplicate(int id)` |
| `reviews/:id` | `EvaluationEditView` | `currentUser`, `evaluationId`, `onBack`, `onDeleted`, `onTransferred`, `onOpenPdfBytes(Uint8List bytes)` |

`showStartReviewDialog({context, currentUser, templateId?, username?, eventId?})
→ Future<int?>` creates a draft and resolves to its id. The caller fixes what
it knows: a profile the member, an enrolment row the member and the event, a
template's *Start* the template. `CoachReviewsView` opens it itself from
*Start* and then calls `onOpenEvaluation` with the new id.

Views take `required UserPrivate currentUser` and callbacks, never routes,
never watch `authStateProvider`, and assert the screen's gate (coach; coach
or admin for the template views; or the member themselves). Templates are
not admin-only: any coach or admin creates, edits, duplicates and deletes
them (an admin's only evaluation role is templates). Restore is not
offered in the UI yet: a deleted template leaves the library; it can be
restored through the API/CLI (tracked separately). PDFs leave
the package only as bytes (`onOpenPdfBytes`); the app decides how to show
them.

**Evidence and the member copy are private** (roles self / coach / admin):
a plain URL is refused without the bearer token. The gallery sends
`imageAuthHeadersProvider` (cl_member_auth) as `httpHeaders`, and a PDF is
downloaded with the session through `clMediaBytesReaderProvider`
(cl_remote_store, `openEvaluationPdf`) and handed over as bytes; a failed
download shows a toast. Never open them by URL.

## Internal structure

```
lib/src/
  constants/  EvaluationViewStrings (all copy), EvaluationViewSizes.
              Refusal codes are the SDK's `SdkErrorCode`.
  models/     Adapters, one per form (form rules 7, 18):
              EvaluationItemAdapter (SDK item variants ↔ EvaluationItemValue;
                copyOf, keepOrigin), EvaluationLayoutAdapter (ids ↔ inline
                layout), EvaluationAnswerAdapter (answers ↔
                EvaluationAnswerValue; yes / no as 1 / 0),
              EvaluationTemplateFormSubmit (create, renameTemplate,
                updateLayout, addItem, replaceItem, removeItem),
              EvaluationTemplateCopy (Duplicate: a template as designer
                values, "Name (copy)", items without id or origin),
              EvaluationAnswerSubmit (putAnswer / clearAnswer;
                clearsEvidence),
              EvaluationStartFormSubmit, EvaluationPeriodFormSubmit
                (updateReviewPeriod: the event and the period through
                `updateEvaluation`, only what changed),
              EvaluationPeriodDates (a day is stored as its UTC midnight),
              EvaluationStep (lifecycle actions by status),
              EvaluationStatusLabels (saved reads "Finalized"; the coach
                view's group order Drafts → Finalized → Published),
              StartReviewOptions (record).
  utils/      EvaluationLayoutSync (one layout-editor change → the atomic
                template call), EvaluationAutosave (answers written once
                settled, in order), EvaluationLifecycle, EvaluationErrorMessage,
                showEvaluationErrorToast, EvaluationNames,
                EvaluationTemplateActions (delete with prompt and toasts),
                StartReviewChoices (also `eventsFor`, the Review Period
                editor's events), the gallery mapper.
  views/      The seven views above.
  widgets/    Rows, dialogs (item, rename, section title, existing question,
              transfer, start, clear-answer prompt), the editor's body and
              its cards (top bar with Back and download, head card with
              status stamp, Review Period card / section / rows, Review
              Management, Review Info, titled card), title bar, and
              evidence slot / tile / uploader / gallery.
```

## Rules this package keeps

- **Forms live in `ui_lib`** (form rule 17): `EvaluationItemForm`,
  `EvaluationTemplateCreateForm`, `EvaluationLayoutEditor`,
  `EvaluationFillBody`, `EvaluationReadBody`, `EvaluationStartForm`,
  `EvaluationPeriodForm`, `RenameForm`. The dialogs hosting them are here.
- **A copy keeps its origin's answer domain.** The item form derives choice
  values from labels; `EvaluationItemAdapter.keepOrigin` puts the origin's
  values back by position (and remaps the coach-note rule), so relabelling a
  copy never trips `ORIGIN_MISMATCH`. Adding or removing choices on a copy is
  left to the server, whose message is shown.
- **A saved template is edited in place, call by call**
  (`EvaluationLayoutSync`): add, replace, remove, or re-lay out. A template
  an evaluation uses says so (`EvaluationTemplate.inUse`): it opens with its
  layout read-only and a plain explanation, and its library row reads
  "In use". A `TEMPLATE_IN_USE` refusal (it came into use after it was
  read) turns it read-only the same way. Renaming stays open.
- **Drafts autosave, so the draft action is "Finalize"** and status `saved`
  reads "Finalized" (the coach view lists Drafts, Finalized, Published,
  then New). The server's status and call stay `saved` / `saveEvaluation`.
  Finalize checks the form first (`EvaluationFillBodyState.validateForSave`),
  after flushing pending answers; the server's `INCOMPLETE` item ids go to
  `markIncomplete`. A reopened draft (one with answers) validates on open.
- **The owner's editor**, top to bottom: Back (no confirmation), the head
  (member name, review title, the website's `StampBadge` in monochrome
  theme colours — Ready once finalized, Published once published, none
  on a draft), Review Period
  (event and period as detail rows; on a draft only, the pencil edits
  both: the event — *General* or one the start dialog would offer for the
  member, the current one kept even when no longer offered — and the
  period; `NOT_ELIGIBLE`, `DUPLICATE_EVALUATION`, `PERIOD_IN_FUTURE` and
  `EVENT_NOT_FOUND` show inline in the editor),
  the fill form, **Review Management** (draft: Finalize, Delete; finalized:
  Publish, Revert to draft, Transfer; published: Unpublish) and **Review
  Info**. Cards follow the member profile's formatting. No member-view
  toggle and no Preview PDF: a finalized or published evaluation reads
  read-only with its private items greyed; a published one downloads its
  member copy from the icon at the top right.
- **Member view**: the review title as the page title, the download icon
  at the top right, the Review Period section without pencil (omitted
  with neither an event nor a period), then the answers.
- **Closing run**: every view keeps the template's order; a trailing
  run of top-level Q & A items shows last, outside any section, as one
  untitled card (`EvaluationClosingRun`, ui_lib).
- **Duplicate** is client-side: `EvaluationTemplateCopy` opens the designer
  pre-filled; the copies are new, unlinked questions. A taken name
  (`TEMPLATE_NAME_TAKEN`) shows inline in the designer and the rename
  dialog; `DUPLICATE_EVALUATION` inline in the start dialog and the Review
  Period editor. Template Delete is always shown, disabled while in use. Restore
  is not offered in the UI yet: a deleted template leaves the library; it
  can be restored through the API/CLI (tracked separately).
- **Outline rows have no delete.** An item or section is deleted from its
  dialog, asked first; the item dialog also asks before dropping changes
  (Cancel, Escape, back) and ignores taps outside. A frozen template opens
  an item read-only (Close only) and a section not at all.
- **Evidence shows once.** On a draft each file is its own card
  (`EvaluationEvidenceTile`, the gallery's own card for its kind) with its
  remove action; otherwise the files are in the gallery.
- **Evidence files are the member's and staff-only.** Each picked file is
  uploaded in one call, `ClEvaluationsMasterNotifier.uploadEvidence`: the
  server stores it with the evaluation's member as uploader and access
  roles `self`, `coach`, `admin` — never public — and links it under the
  item. Removal is `detachEvidence`; the owner's listing is
  `clEvaluationMediaProvider`. No SDK call is made here.
- **Clearing an answer that has evidence asks first**
  (`confirmClearAnswer`), since the server detaches the evidence with it;
  on cancel the saved answer goes back into the form and nothing is
  written.
- **Toasts name the section; errors never show the raw exception**
  (`EvaluationErrorMessage`). `ORIGIN_MISMATCH` shows the server's message.
- No colour coding: a status is plain text.

## Dependencies

Allowed: `cl_remote_store`, `ui_lib`, `club_sdk_2`, `cl_gallery_viewer`,
`flutter`, `flutter_riverpod`, `shadcn_ui`; `cl_member_auth` for
`imageAuthHeadersProvider` only (views still take the user and never watch
`authStateProvider`); `cl_server_config` in tests only (to fix the API base
URL).

Forbidden: `cl_member_zone`, the other feature packages, `go_router`,
Material widgets.

`club_sdk_2` and `cl_gallery_viewer` are git dependencies pinned by SHA,
at the same refs as the sibling packages; the commented
`dependency_overrides` entries point at the workspace's `packages/`.

## Conventions

- Root [`../CLAUDE.md`](../CLAUDE.md) — module view wrapping, no hardcoded
  routes, SDK access boundary, view permission guidelines, form rules,
  section-wise editors, UI style.
- [`../docs/coding_rules.md`](../docs/coding_rules.md) — one class per file,
  no `_` declarations in `lib/`, folder roles, size limits.
- [`../docs/dart-data-class.md`](../docs/dart-data-class.md) — this package
  defines no data classes; it uses the SDK's and `ui_lib`'s models directly
  and keeps view options as records.

## Testing

`flutter test` (also `just unit-test cl_club_evaluation`): adapters (every
item variant round-trips; copies keep their origin values), the layout sync,
and widget tests of every view and the start dialog over stub masters
(`test/support/evaluation_scope.dart`). Tests added for #173 are named
`Issue 173: …`. Workflow coverage against a live server belongs in
`cl_club_app/example/integration_test/` once #174 wires the screens.
