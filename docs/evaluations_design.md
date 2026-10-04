# Member evaluations — design

Status: **draft, sections 1 and 3 of 4** (2026-10-01). Each section is agreed
before the next is written and before any code is built on it. This document
is intermediate: once section 3 is agreed, club_server's
`docs/evaluation_requirements.md` is rewritten to match it (3.9).

| # | Section | State |
|---|---|---|
| 1 | Glossary and data structure | agreed in discussion; written for review |
| 2 | Models (client package and SDK) | done in the SDK (club_sdk#98); the client uses them directly |
| 3 | Server changes and API | agreed in discussion; written for review |
| 4 | Views and UI workflow | agreed in discussion; written for review |

Sources: club_server `docs/evaluation_requirements.md` (rules cited as R-n),
`club_server/db/models/evaluation*.py`, `club_server/schemas/evaluation*.py`,
and the SDK `club_sdk_2` (`lib/sdk/interfaces/evaluation.dart`). The client
package is **`cl_club_evaluation`**, inside club_core.

---

## 1. Glossary and data structure

### 1.1 Glossary

Every model, widget, util, database column and document uses these words.
**"Survey" is not one of them.** The item and answer structures follow SurveyJS
closely, but SurveyJS names appear only in a codec, if we ever exchange data
with SurveyJS's own tools.

| Term | Meaning |
|---|---|
| **Evaluation template** | A reusable definition an evaluation is written against: a name, its items and their layout. Created and changed by any staff member, coach or admin (R46); its name is unique among live templates (R49a); usable for any evaluation, general or event; frozen once an evaluation uses it. |
| **Item** | One question or one info text of a template. |
| **Section** | A titled group of items. Sections are part of the template's **layout**, not items. One level only: a section holds items, never another section. Its title is plain text. |
| **Layout** | The template's ordered arrangement of items and sections. |
| **Info text** | Markdown text shown to the reader; asks nothing. |
| **Question** | An item that collects an answer. Its question text (markdown) is the only text the designer types. |
| **Question type** | **Rating**, **Yes / No**, **Single choice**, **Multiple choice**, **Number**, **Q & A** (a question with a written, markdown answer). |
| **Rating scale** | **Stars**, a **range** (min..max, e.g. 1..10), or **labelled levels** (e.g. Needs work, Developing, Good, Excellent — values 1..n by their order). |
| **Origin** | For an item copied from another template, the item it was first copied from. Items with the same origin are the same question, compared across templates. |
| **Private item** | An item marked `is_private`: it and its answer are never shown to the member — not in the member view, not in the PDF. A coach's private notes are a private Q & A item. |
| **Evaluation** | A coach's assessment of one member against one template: **general**, or about one **event** (a programme, camp or one-off). Only coaches write evaluations; an admin writes templates and evaluates no one. |
| **Created for** | The member the evaluation is about. |
| **Created by** | The coach who started the evaluation. Never changes. |
| **Owner** | The coach the evaluation is assigned to after a transfer. The **effective owner** is the owner, else the creator; it is the only person who sees the evaluation before it is published, and the only one who may edit, save, publish, unpublish, revert or delete it. It signs the PDF. |
| **Transfer** | Handing an evaluation to another coach. Done by the effective owner, or by an admin who knows its id; the target must be eligible (R37). |
| **Review period** | The optional start and end dates the evaluation covers, on a general or an event evaluation. |
| **Status** | **Draft** (work in progress; gaps allowed; the only status in which answers change), **saved** (declared complete; required answers enforced; read-only — revert to draft to edit), **published** (the member sees it). Draft and saved are seen by the effective owner only. |
| **Answer** | The value given to one question. |
| **Coach note** | A note on one answer, which the member sees, written in the question's comment area. A question may require a coach note for some answers (e.g. a rating of *Needs work*, or *No*). |
| **Evidence** | Optional files attached to an answer to justify it — **images, videos and PDFs only** — on questions that allow it (`allowEvidence`). Uploaded through `/media` and linked to the evaluation with the item's id as its tag; shown with the gallery viewer (`cl_gallery_viewer`); in the PDF, the word *Evidence* links to each file. The member sees it exactly when they see the item: evidence on a private item never reaches them. |
| **Member copy** | The PDF of a published evaluation as the member sees it: no private items. Generated on request, never stored (3.7). |

### 1.2 Data structure

Times are stored as epoch milliseconds in UTC (`BigInteger`, set by
`now_utc_ms()`); the API exposes them as ints with a `Utc` suffix
(`createdAtUtc`), and the SDK as UTC `DateTime`s of the same names. The
database stores ids; screens show titles and names.

```
users ───────────────┐ created_by
                     ▼
            evaluation_templates ──1:N──► evaluation_template_items
                     ▲                                ▲
         template_id │                                │ item_id
                     │                                │
users ── created_for / created_by / owner ──► evaluations ──1:N──► evaluation_answers ──1:N──► evaluation_answer_choices
events ── event_id ───────────────────────────┘        │
                                                       └──1:N──► evaluation_media (evidence) ──► media (uuid)
```

#### `evaluation_templates` — front matter and layout

| Column | Type | Constraints |
|---|---|---|
| `id` | int | PK |
| `name` | text ≤ 200 | not null; says what the template is for |
| `layout` | JSON | not null; `[LayoutEntry]`, below |
| `created_by` | varchar(50) | FK → `users.username` |
| `created_at`, `updated_at`, `deleted_at` | BigInteger ms | soft delete (R26) |

```
LayoutEntry := itemId                                  // an item outside any section
             | { section: string, items: [itemId] }    // a titled group; one level only
```

For example `[11, {"section": "Skating", "items": [12, 13]}, 14]`. Items are
identified by their database `id` only; there is no other key. Every item
appears exactly once; a section may be empty while the template is
being designed, but its title is required.

#### `evaluation_template_items` — one row per question or info text

| Column | Type | Constraints |
|---|---|---|
| `id` | int | PK |
| `template_id` | int | FK → `evaluation_templates.id`, `ON DELETE CASCADE` |
| `origin_item_id` | int, nullable | FK → `evaluation_template_items.id`, `SET NULL`; set on a copy: the source's origin, else the source — never a copy of a copy |
| `type` | text | not null; `rating`, `yesNo`, `singleChoice`, `multipleChoice`, `number`, `qa`, `info` |
| `question` | text (markdown) | not null, except for `info` |
| `element` | JSONB | not null; the variant selected by `type` (below) |
| `is_private` | bool | not null, default false |

The whole row is frozen once any evaluation uses its template (R27,
club_server#533).

**`element` is a tagged union**, selected by `type`; each variant allows only
its own properties:

```
element := RatingElement          when type = rating
         | YesNoElement           when type = yesNo
         | ChoiceElement          when type = singleChoice | multipleChoice
         | NumberElement          when type = number
         | QaElement              when type = qa
         | InfoElement            when type = info

CommentArea   := { showCommentArea?: bool, requireCommentFor?: [value] }
Evidence      := { allowEvidence?: bool }               // images, videos, PDFs

RatingElement := CommentArea + Evidence + {
  isRequired?: bool,
  rateType?: "stars",
  rateMin?: int, rateMax?: int,                  // stars or range (default 1..5)
  rateValues?: [{ value: int, text: string }]    // labelled levels, values 1..n by order
}                                                // rateValues XOR rateMin/rateMax
YesNoElement  := CommentArea + Evidence + { isRequired?: bool, labelTrue?: string, labelFalse?: string }
ChoiceElement := CommentArea + Evidence + { isRequired?: bool,
                                 choices: [{ value: string, text: string }] }  // ≥ 1; values from labels
NumberElement := CommentArea + Evidence + { isRequired?: bool }
QaElement     := Evidence + { isRequired?: bool }
InfoElement   := { markdown: string }
```

`requireCommentFor` lists the answers that make the coach note required.
`allowEvidence` lets the person filling the evaluation attach evidence to the
answer; info items take none.

#### Reusing a question: copy with an origin

Items belong to their template; there is no shared item table. Reuse is a
**copy**:

- The designer's **+ Add** offers **Existing question** next to the new-item
  types: a picker searching the items of every template (one query over
  `evaluation_template_items`). Choosing one **copies** it into this template —
  type, question, `element` — as a new row with its own `id`, and records
  `origin_item_id`.
- **The same origin means the same question.** A copy keeps its origin's
  `type` and answer domain: the same scale (stars, range, or the same level
  values), the same choice values. Wording, level and choice labels, required,
  private and comment-area settings may differ. The server checks this on
  every write of a copy (422 `ORIGIN_MISMATCH` otherwise).
- Editing a copied question changes only this template; freezing stays per
  template (R27).

#### `evaluations` — front matter

| Column | Type | Constraints | Shown as |
|---|---|---|---|
| `id` | int | PK | |
| `template_id` | int | FK → `evaluation_templates.id`, `RESTRICT` (R27) | the template's name |
| `created_for` | varchar(50) | FK → `users.username` | the member's name |
| `event_id` | int, nullable | FK → `events.id`; null = general | the event's title, or "General" |
| `period_start_utc`, `period_end_utc` | BigInteger ms, nullable | both or neither; start ≤ end; general or event | review period |
| `created_by` | varchar(50) | FK → `users.username`; never changes | |
| `owner` | varchar(50), nullable | FK → `users.username`; null = owned by `created_by`; set by a transfer | |
| `status` | text | `draft` / `saved` / `published` (R14–R20) | |
| `created_at`, `updated_at`, `published_at`, `deleted_at` | BigInteger ms | | |

`event_id` keeps the eligibility rules (R28–R33): for an event evaluation the
coach must coach the event and the member must be enrolled in it.

#### `evaluation_answers` — one row per answered item

| Column | Type | Constraints |
|---|---|---|
| `id` | int | PK |
| `evaluation_id` | int | FK → `evaluations.id`, `ON DELETE CASCADE` |
| `item_id` | int | FK → `evaluation_template_items.id`, `RESTRICT`; unique (`evaluation_id`, `item_id`); the item belongs to the evaluation's template |
| `value_num` | numeric, nullable, indexed | rating, Yes / No (1 / 0), number |
| `value_text` | text, nullable | single-choice value, or a Q & A answer (markdown) |
| `coach_note` | text, nullable | the coach note on this answer |

At most one of `value_num`, `value_text` or choice rows is set, by the item's
type; an answer may carry only a coach note or evidence. An answer to a private
item — its value, coach note and evidence — never reaches the member: an item
is private or public as a whole, and answers have no private note of their own.

**An answer's evidence** is the `evaluation_media` rows of its evaluation whose
`tag` is the item's id. Clearing an answer detaches its evidence.

#### `evaluation_answer_choices` — a multiple-choice answer's selections

| Column | Type | Constraints |
|---|---|---|
| `answer_id` | int | FK → `evaluation_answers.id`, `ON DELETE CASCADE` |
| `value` | text | one of the item's choice values |
| | | PK (`answer_id`, `value`) |

#### `evaluation_media` — evidence; exists, unchanged

`evaluation_id` → `evaluations.id` (`CASCADE`), `media_uuid` → `media.uuid`,
`tag` = the item's `id` as text, `metadata_value` (file name and kind). The
same shape as the server's other media-link tables. Attaching is refused unless
the tag is an item of the evaluation's template with `allowEvidence`, and the media is an
image, a video or a PDF.

In the member copy PDF the word **Evidence** (or *Evidence 1*, *Evidence 2*…)
links to each file's media URL as served today. Such a link opens only for a
signed-in user allowed to see the media; links that work outside the app are
left for later.

#### Replaced

| Today | Becomes |
|---|---|
| `evaluation_categories` | `evaluation_template_items` |
| `evaluation_scores` | `evaluation_answers` (+ `evaluation_answer_choices`) |
| template `description`, `scopes` | layout and info items; templates suit any evaluation |
| evaluation `subject_username`, `author_username` | `created_for`; `created_by` + `owner` |
| evaluation `scope_type` + `scope_event_id` | `event_id` (null = general) |
| evaluation `comment`, `coach_note` | answers, per-answer `coach_note`, private items |

### 1.3 Comparing a question across evaluations

```sql
-- "Forward stride" for every member reviewed with one template
SELECT e.created_for, e.published_at, a.value_num, a.coach_note
FROM evaluation_answers a
JOIN evaluations e ON e.id = a.evaluation_id
WHERE a.item_id = :item AND e.status = 'published'
ORDER BY e.created_for, e.published_at;
```

The same works **across templates** by origin, since items with one origin
are the same question:

```sql
-- "Forward stride" across every template that asks it
SELECT e.created_for, t.name, e.published_at, a.value_num
FROM evaluation_answers a
JOIN evaluation_template_items i ON i.id = a.item_id
JOIN evaluations e ON e.id = a.evaluation_id
JOIN evaluation_templates t ON t.id = e.template_id
WHERE COALESCE(i.origin_item_id, i.id) = :origin AND e.status = 'published'
ORDER BY e.created_for, e.published_at;
```

### 1.4 Who validates what

| Rule | Where |
|---|---|
| Each answer matches its item's type and `element` (range, levels, choices) | Server, on every write (R10 generalised); client form fields too. |
| Required answers, and coach notes required for an answer | Client form validation and the server, on **save** (draft → saved). Drafts may have gaps. |
| Lifecycle, permissions, eligibility, visibility (effective owner, private items and their evidence) | Server (R14–R45, as changed in 3.9). |
| Items well-formed (union variant) and the layout referencing every item once | Client designer and the server, on template write. |
| A copy keeps its origin's type and answer domain | Server, on every write of a copy (`ORIGIN_MISMATCH`). |
| A used template's items and layout unchanged | Server (R27). |
| Length of names, questions, notes and answers | Client only; the server sets no limits (3.6). |

### 1.5 Settled questions

- **Migration:** none. No deployment holds real evaluation data, so the old
  tables are replaced outright (3.8).
- **The member copy PDF:** stored as media on publish, replaced on republish; an owner preview is generated on request (3.7).
- **Cross-template comparison:** copy with an origin (1.2).
- **Item identity:** the database `id`; there is no separate key.

### 1.6 API representation

The database stores an item's variant as JSONB; the **API speaks the strict
union**, so the server validates every request against it. FastAPI and Pydantic
do this with a **discriminated union** on `type`: a request whose `type` matches
no variant, carries a property its variant does not allow, or breaks a
variant's own rules is rejected with a 422 naming the field. OpenAPI documents
the union as `oneOf` with a discriminator mapping on `type`.

```python
class CommentArea(CamelCaseModel):
    show_comment_area: bool = False
    require_comment_for: list[int | str | bool] = []

class Evidence(CamelCaseModel):
    allow_evidence: bool = False                   # images, videos, PDFs

class ItemBase(CamelCaseModel):
    model_config = ConfigDict(extra="forbid")      # unknown properties → 422
    is_private: bool = False
    origin_item_id: int | None = None              # set when copying an existing question

class RatingItem(ItemBase, CommentArea, Evidence):
    type: Literal["rating"]
    question: str                                  # markdown
    is_required: bool = False
    rate_type: Literal["stars"] | None = None
    rate_min: int | None = None
    rate_max: int | None = None
    rate_values: list[RateLevel] | None = None     # labelled levels, values 1..n

    @model_validator(mode="after")
    def scale(self): ...                           # rate_values XOR rate_min/rate_max; min < max

class YesNoItem(ItemBase, CommentArea, Evidence):          # type: "yesNo"; question; is_required;
    ...                                            # label_true; label_false
class ChoiceItem(ItemBase, CommentArea, Evidence):          # type: "singleChoice" | "multipleChoice";
    ...                                            # question; is_required; choices (≥ 1, unique)
class NumberItem(ItemBase, CommentArea, Evidence):          # type: "number"; question; is_required
    ...
class QaItem(ItemBase, Evidence):                          # type: "qa"; question; is_required
    ...
class InfoItem(ItemBase):                          # type: "info"; markdown
    ...

TemplateItem = Annotated[
    RatingItem | YesNoItem | ChoiceItem | NumberItem | QaItem | InfoItem,
    Field(discriminator="type"),
]

class SectionInput(CamelCaseModel):
    section: str = Field(min_length=1)
    items: list[TemplateItem]

class EvaluationTemplateCreate(CamelCaseModel):
    name: str = Field(min_length=1)
    layout: list[TemplateItem | SectionInput]     # items inline; the server assigns ids
```

**Rules checked by model validators**

| Scope | Rules |
|---|---|
| A variant | its scale (ratings); at least one choice, values unique (choices); `requireCommentFor` names only answers the question can take, and only with the comment area on |
| The template | at least one question; on create, items arrive inline in the layout, so each is placed once by construction; later layout writes must name every item id of the template exactly once, and no other |

**Between the API and the database**

| API (one variant object) | Database row of `evaluation_template_items` |
|---|---|
| `id` (read only), `type`, `question`, `isPrivate`, `originItemId` | columns |
| every other property of the variant | `element` JSONB — that variant's JSON |

Reads rebuild the variant from the row; the stored JSONB is always a value the
union accepted.

**The SDK mirrors the union**: a Dart sealed `EvaluationTemplateItem` with one
subclass per variant, its `fromJson` switching on `type`.

**Answers** are typed by shape in the schema (`valueNum`, `valueText`,
`choices`, `coachNote`, and, as returned, `evidence: [{mediaUuid, name,
kind}]` with `kind` one of `image`, `video`, `pdf`, joined from
`evaluation_media` by tag). Whether an answer is valid depends on its item (a
rating within *that* item's levels, a choice among *its* choices), so the
service validates each answer against its item's variant when it writes it —
R10, generalised from scores to every answer type.

---

## 2. Models (client package and SDK)

The SDK models them (club_sdk#98, `club_sdk_2` 0.8.0): a sealed
`EvaluationTemplateItem` with one subclass per type, `EvaluationLayoutEntry`,
`EvaluationTemplate`, `EvaluationAnswerInput` / `EvaluationAnswer`,
`EvaluationEvidence`, `EvaluationStaffView`, `EvaluationMemberView`. The client
uses them directly (coding rule 10); forms speak form-local values and an
adapter per form translates (form rules 7, 18).

---

## 3. Server changes and API

The flow stays what the server has today: CRUD for templates, CRUD for
evaluations, the lifecycle steps, and media. What changes is the shape of
the content: items and layout instead of categories, answers instead of
scores. Each item and each answer is edited **atomically**, so a designer or
a coach never resends a whole template or evaluation to change one question.

### 3.1 Roles

| Who | Templates | Evaluations |
|---|---|---|
| **Admin** | create, edit, delete, restore | none: sees no evaluation, writes none; may **transfer** one by its id |
| **Coach** | create, edit, delete, restore | create; as the effective owner, edit, save, publish, unpublish, revert, delete, transfer; read any member's **published** evaluations through the member surface |
| **Super-admin** | hard delete | hard delete |
| **Member** | — | their own **published** evaluations, without private items |

### 3.2 Endpoints

**Templates** — `/evaluations/templates` (staff read and write)

| Method and path | Body | Does |
|---|---|---|
| `GET ""`, `GET /deleted`, `GET /by_id/{id}` | | list (paginated), list soft-deleted, read: front matter, `layout`, `items` |
| `POST ""` | `{name, layout}`, items inline in the layout | create in one call (1.6); the response carries the assigned ids |
| `PATCH /by_id/{id}` | `{name?, layout?}` | rename; reorder or regroup — the layout of item ids must still place every item once |
| `POST /by_id/{id}/items` | `{item: TemplateItem, section?: string}` | add an item — new, or a copy carrying `originItemId` — appended to the layout (inside `section` when given); returns its id |
| `PUT /by_id/{id}/items/{itemId}` | the whole variant | replace one item in place; it keeps its id, `type` (422 `ITEM_TYPE_FIXED`) and origin |
| `DELETE /by_id/{id}/items/{itemId}` | | remove one item, and its layout entry |
| `DELETE /by_id/{id}`, `POST /by_id/{id}/restore`, `DELETE /by_id/{id}/hard` | | soft delete, restore, hard delete (R25–R26) |
| `GET /items?search=&type=` | | items of every template, for **Existing question** (1.2): id, type, question, `element`, origin, and the template's name |

Every write to a template that an evaluation uses → 422 `TEMPLATE_IN_USE`
(R27). Every write of a copy checks it against its origin → 422
`ORIGIN_MISMATCH` (1.2).

**Evaluations** — `/evaluations` (coaches; the effective owner unless said)

| Method and path | Body | Does |
|---|---|---|
| `GET ""`, `GET /deleted` | | the caller's own evaluations: filters `status`, `createdFor`, `eventId` or `general`, paginated |
| `GET /by_id/{id}` | | the staff view: front matter and `answers`, each naming its `itemId`, with evidence |
| `POST ""` | `{templateId, createdFor, eventId?, periodStartUtc?, periodEndUtc?}` | create a **draft** with no answers; eligibility R28–R33 for an event |
| `PATCH /by_id/{id}` | `{periodStartUtc?, periodEndUtc?}` | change the review period (draft only) |
| `PUT /by_id/{id}/answers/{itemId}` | `{valueNum?, valueText?, choices?, coachNote?}` | write one answer, replacing it (draft only) |
| `DELETE /by_id/{id}/answers/{itemId}` | | clear one answer and detach its evidence (draft only) |
| `POST /by_id/{id}/save` | | draft → saved: refused with 422 `INCOMPLETE` naming the item ids when a required answer or a required coach note is missing |
| `POST /by_id/{id}/publish`, `/unpublish`, `/revert` | | saved → published, published → saved, saved → draft (R14–R20) |
| `POST /by_id/{id}/transfer` | `{owner}` | sets `owner`, answers 204 with no body; the effective owner or an admin; before publication; target a coach and eligible (R36–R37) |
| `DELETE /by_id/{id}`, `POST /by_id/{id}/restore`, `DELETE /by_id/{id}/hard` | | soft delete (draft only, R24), restore, hard delete (super-admin) |

`POST /evaluations/apply` (create from a template seeded with default scores)
is **removed**: creating an evaluation names its template, and answers start
empty.

**Evidence** — `/evaluations/by_id/{id}/media`, unchanged in shape. The tag is
the item's id; attaching is refused unless that item has `allowEvidence` and
the file is an image, a video or a PDF, and only while the evaluation is a
draft.

**Member surface** — `/myevaluations/by_id/{username}`, unchanged in shape:
the member, or any coach, reads that member's published evaluations. The
member view embeds what is needed to render it — the template's `name`, its
layout with private items removed (and sections left empty by that dropped),
the public items, their answers and their evidence — and nothing private.

| Method and path | Does |
|---|---|
| `GET /by_id/{username}/{id}/media` | evidence on public items, and the stored member copy under `member_copy` (3.7) |

### 3.3 Visibility

- A **draft or saved** evaluation exists only for its effective owner. Anyone
  else asking for it by id — a coach, an admin, the member — gets not-found.
  An admin's transfer by id is the one exception, and it returns no content.
- A **published** evaluation is seen by the member and by any coach, through
  the member surface, without private items. The effective owner also keeps
  the full staff view.
- A **private item** — its answer, coach note and evidence — is seen only by
  the effective owner, in any status.
- The **coach note** on a public item is part of the member's view.

### 3.4 Audit

Only what helps trace an issue is logged, naming the actor, the evaluation and
the actor's IP: **save, publish, unpublish, revert and transfer**. Creating an
evaluation, editing a draft and deleting a draft are not logged: an evaluation
enters the audit trail when it is first saved. Template writes are logged as
today.

### 3.5 Notifications

Unchanged (R53–R54): the member on **publish** and on **unpublish**, the
receiving coach on **transfer**.

### 3.6 Limits

The server sets no length limits on names, questions, notes or answers. Clients may restrict lengths in their
forms.

### 3.7 The member copy PDF

Always as the member sees it (no private items); there is no coach version.

- **Stored on publish** as an ordinary media item (`/media`, type `pdf`),
  linked to the evaluation in `evaluation_media` under the tag
  `member_copy`. Its uploader is the member, and its access roles are
  `["self", "coach", "admin"]`: the member and staff download it, nobody
  else. It is listed in the member's view of the evaluation's media, and,
  like the rest, reaches the member only while published.
- **Publishing again replaces it**: the old file is detached and
  soft-deleted (recoverable through the media module). Hard-deleting the
  evaluation retires it the same way.
- **Preview**: `GET /evaluations/by_id/{id}/pdf`, for the effective owner, at
  any status — generated on request, never stored.

Its layout is the one the `cl_survey_forms` prototype built:

- tall half-width pages, 105 × 297 mm, printed two to an A4 sheet;
- a framed page with the club's logo and name, the member, the event or
  *General*, the review period, and the coach who signs it (the effective
  owner);
- the questions as a table, question and answer in two equal columns, the
  coach note under the answer in a smaller face;
- printed text in Lato; filled-in answers in a handwriting face (Patrick
  Hand);
- ratings drawn as filled stars (star ratings), a pie ring with "value/max"
  (range ratings) or the level's label (labelled levels); Yes / No and
  choices as the chosen label(s), handwritten;
- a section kept whole on one page when it fits; a table split across pages
  closes its border at the page start;
- the word **Evidence** linking to each file of an answer.

The look — accent colour, background, logo — is one **club-wide setting**,
not per template.

### 3.8 Migration

None. No deployment holds real evaluation data, so `evaluation_categories`,
`evaluation_scores` and the replaced columns (1.2, *Replaced*) are dropped and
the new tables created by one migration.

### 3.9 Changes to the server requirements (R-n)

`docs/evaluation_requirements.md` is rewritten in its standard format on the
implementation branch: kept rules keep their ids; a changed rule is marked
`[GAP]` with the issue until its test lands; a removed rule goes together with
its test markers, so the requirement-coverage test stays green.

| Rule | Change |
|---|---|
| R1–R3 | Scope becomes `event_id`: null = general, else the event. Same meaning. |
| R4 | A review period is allowed on general evaluations too. |
| R8 | `created_for`, `created_by` (never changes) and `owner`, instead of subject and author. |
| R9 | Content is answers, each with an optional coach note and evidence, plus private items; replaces scores, comment and coach note. |
| R10, R12 | Every answer is validated against its item's variant (`INVALID_ANSWER`); items replace categories. |
| R11 | Comparison is by item, and across templates by origin (1.3). |
| R15 | Save enforces required answers and required coach notes (`INCOMPLETE`). |
| R21–R22 | Only a draft may be edited; a saved or published one → 422 `INVALID_STATE`, remedy: revert. |
| R23 | `event_id` and `created_for` are fixed at creation; the period may change in draft. |
| R27 | A used template's items and layout are frozen too. |
| R34–R36 | Only coaches create; the effective owner acts; transfer by the effective owner or an admin. |
| R39, R41–R42 | The coach note is member-visible; private items replace the staff-only note. Unpublished evaluations are seen by the effective owner only; an admin sees none. |
| R45–R46 | Evaluation writes need the coach role; templates are written and read by any staff member. |
| R49–R50 | A template is a name, a layout and items; creating an evaluation starts with no answers; `/apply` removed. |
| R51 | Removed: templates have no scopes. |
| R52 | Audit is save, publish, unpublish, revert and transfer only. |
| R56a | Evidence visibility follows its item's privacy; the `shared_` tag prefix goes. |
| R57–R58 | Filters are `createdFor`, `eventId` / general, and status, over the caller's own evaluations. |
| new | Layout validity; copies and `ORIGIN_MISMATCH`; per-item and per-answer endpoints; evidence only on `allowEvidence` items and only images, videos and PDFs; the member copy PDF. |

### 3.10 Open points

1. **A template with no questions:** refused at create (422) — settled in
   club_server#535 (R49).
2. **Where the club-wide PDF look is stored**, and its defaults.

---

## 4. Views and UI workflow

Everything below is shown only when the server's `evaluations` capability is
on (`evaluationsProvider`, beside `creditSystemProvider`); off, no menu entry,
button or route appears.

### 4.1 Who sees what

| Role | Sidebar | Elsewhere |
|---|---|---|
| Every member | **Reviews** (Main): their published reviews | — |
| Coach (admin + coach included) | **Reviews** (Club Management): the coach view, with **Manage Templates** at its foot | **Add Review** on a member's profile and on each enrolment row |
| Admin, not a coach | **Reviews** (Club Management): the template view | — |

The server enforces the same split (R34, R38a, R42, R46): any staff member
writes templates, an admin evaluates no one, and only the effective owner
sees an unpublished evaluation. Restoring a deleted template is not offered
in the UI yet (the API and CLI can).

### 4.2 Screens and views

| Route (`/memberzone/…`) | Screen → view | Content |
|---|---|---|
| `reviews/mine` | `MyReviewsScreen` → `MyReviewsView` | the member's published reviews, newest first; empty state when none |
| `reviews/mine/:id` | `MyReviewScreen` → `EvaluationReadView` | read-only member view: sections, answers, coach notes, evidence in the gallery viewer (requests carry the session's headers); the review's title as the page title, a Review Period section (event and period, when set), the answers with a trailing run of top-level Q & A shown last as one untitled card; the download icon at the top right downloads the stored member copy with the session and opens it locally — evidence and the copy are private, never opened by URL |
| `reviews` | `ReviewsScreen` → `CoachReviewsView` or `TemplateLibraryView` by role | coach: their evaluations grouped Drafts, Finalized, Published, then the templates to start from, and **Manage Templates** at the bottom right; admin who does not coach: the templates, **Add template** |
| `reviews/templates` | `TemplateLibraryScreen` → `TemplateLibraryView` | coaches and admins: the template library — create, open, **Duplicate** (a copy with new, unlinked questions), **Delete** (disabled while in use) |
| `reviews/templates/new` (`?copy=<id>`) | `TemplateCreateScreen` → `TemplateCreateView` | the designer: name, then items and sections (one full create form, form rule 19); pre-filled from a template to duplicate it; a taken name is shown inline |
| `reviews/templates/:id` | `TemplateDetailScreen` → `TemplateDetailView` | the template, edited section by section in place: rename dialog, per-item editor, layout (reorder with the **Sort** checkbox, sections); frozen once used (R27) |
| `reviews/:id` | `ReviewEditScreen` → `EvaluationEditView` | the owner's review: Back; a head with the member, the review's title and a stamp (Ready once finalized, Published once published); **Review Period** (event and period; the pencil changes both on a draft); the answers (editable on a draft, read-only with private items greyed once finalized); **Review Management** (draft: Finalize, Delete; finalized: Publish, Revert to draft, Transfer; published: Unpublish) and **Review Info**; a published review's member copy from the download icon |

Each screen gates and forwards `currentUser` and callbacks (module view
wrapping rule); views take callbacks, never routes.

### 4.3 Starting a review

- **From a member's profile:** *Add Review* → a dialog: template, then an
  event the member attended that the coach coaches, or *General* — and an
  optional period. Creates the draft and opens it.
- **From an enrolment row:** *Add Review* → the same dialog with the event
  fixed.
- **From the coach view:** a template's *Start* → the same dialog with a
  member picker first.

The server checks eligibility (R28–R33); the dialog shows its refusal. A
period ends on or after its start and not after today (R4), and a coach
holds one review per member, template and exact period (R7,
`DUPLICATE_EVALUATION`); both refusals show inline.

### 4.4 Filling and saving

- Each answer is written when its field settles (`putAnswer`); clearing a
  field clears the answer (`clearAnswer`). A draft may have gaps.
- **Save** runs the ShadForm validation (required answers, coach notes
  required for an answer) before calling save; the server's `INCOMPLETE` names
  the same items and is shown on them.
- Saved and published are read-only; *Revert to draft* (and *Unpublish* first
  when published) makes it editable again (R22).
- Evidence: images, videos and PDFs, uploaded through `/media` and attached
  under the item's id, shown with `cl_gallery_viewer`.

### 4.5 Where the code lives

- **`ui_lib`** (SDK-free, no Riverpod, form rule 17): the answer inputs
  (stars, range slider, option buttons, choices, text, number, coach note),
  the item editor form and its validators, the layout list, the template
  create form, the evaluation fill form, the read-only renderer — ported from
  the `cl_survey_forms` prototype with evaluation names.
- **`cl_club_evaluation`** (new feature package): the connected views above,
  the adapters (`build<X>FormInitialValues`, `<X>FormSubmit`), the start
  dialog, the template library and coach lists.
- **`cl_remote_store`**: `evaluationsProvider`; masters for templates, the
  caller's evaluations and the member's published ones; all SDK calls.
- **`cl_member_zone`**: the screens and the two sidebar entries;
  **`cl_club_members`** / **`cl_club_events`**: the *Add Review* actions;
  **`cl_club_app`**: the routes; **`cl_club_communication`**: deep links for
  the evaluation notifications.

