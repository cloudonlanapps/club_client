# Applications and the extended profile — design (2026-10-26)

Status: **implemented** (2026-10-27): club_server#94, club_sdk#67,
club_cli#39, club_client#322. The PDF is the prototype's, ported into the
server. Where the build differs from this text: every application route,
reads included, answers 503 while the module is off (as evaluations and
credits do); the profile options are edited on Club Details, which is
super-admin only.

A club that needs a physically signed application form from each member (a
registration form for a camp, a trial or a championship) gets it from the
server as a PDF, filled from the member's profile, which the member prints,
puts a photo on, signs and hands in.

Two optional, independent features, each a deploy flag reported in
`/v1/capabilities`:

| flag | capability | what it switches |
|---|---|---|
| `EXTENDED_PROFILE_ENABLED` | `extendedProfile` | the extra profile fields in the app |
| `APPLICATIONS_ENABLED` | `applications` | the Applications menu, templates and PDFs |

`applications` is reported `true` only when `APPLICATIONS_ENABLED` **and**
`IDENTITY_VERIFICATION_REQUIRED` are both on. When a flag is off the server
still stores and returns the data (the schema never varies with
configuration); the feature's write and PDF routes answer 503 like other
disabled modules, and the app hides it.

## 0. Three kinds of language — kept apart

| | what | where it lives | who sets it |
|---|---|---|---|
| **App / website language** | the language the app and site are shown in (localisation, ARB files) | the client | not part of this work; untouched |
| **Form print languages** | English, or English and one other language, that an application's PDF is printed in | each application template | admin, per application |
| **Member's preferred language** | a fact about the member, printed on the form | the member's profile, chosen from a club list | member |

None of them reads another: every member gets the same form for an
application, whatever their preferred language, in an app shown in whatever
language the app is in.

---

## 1. Extended profile

### 1.1 Fields (on `users`, all optional)

| field | type | edited by | notes |
|---|---|---|---|
| `club_district` | text | self, admin | "Club / District" |
| `preferred_position` | text | self, admin | one of the club's positions (§1.2) |
| `past_experience` | text (multi-line) | self, admin | |
| `nationality` | text | self, admin | |
| `preferred_language` | text | self, admin | one of the club's languages (§1.2) |
| `guardian` | JSON `{name, relation, phone}` | self, admin | separate from the emergency contact |
| `membership_date` | date (UTC midnight) | admin only | §1.3 |

Visibility follows the existing personal details: the member and admins.
Each is a section editor in the profile (rules 19–21), sending only its own
fields:

- **Sports details** — club/district, preferred position, past experience
- **Background** — nationality, preferred language
- **Guardian** — name, relation, phone (phone validated like other phones)
- **Membership date** — in the account section; admin-editable

From club_server#3: nationality, preferred language and membership date move
here; **tier is dropped**, and #3 is closed once this issue is filed.

### 1.2 Club-set choices

A system preference `profile_options`, admin-editable (validated on write),
edited in the app's Club Details page. The languages are the club's
languages (club_server#133, club_client#396): each a code and a name,
English (`en`) always first and never removed. A member chooses a language
by its name; the codes are also the languages an application may print in,
and a position carries its label in each of them.

```json
{
  "positions": [
    {"value": "Forward", "label": {"en": "Forward", "mr": "फॉरवर्ड", "hi": "फ़ॉरवर्ड"}},
    {"value": "Defense", "label": {"en": "Defense", "mr": "डिफेन्स", "hi": "डिफ़ेंस"}},
    {"value": "Goalie",  "label": {"en": "Goalie",  "mr": "गोलकीपर", "hi": "गोलकीपर"}}
  ],
  "languages": [{"code": "en", "name": "English"}, {"code": "mr", "name": "Marathi"},
                {"code": "hi", "name": "Hindi"}]
}
```

The server checks a member's `preferred_position` / `preferred_language`
against the list when it is **written**; a value whose option is removed later
stays as it is and still prints. A member's `preferred_languages` hold
names, so they are kept as they were when the codes came in.

### 1.3 Membership date

- Set to the approval day when an admin approves a member and it is blank; an
  admin-created (directly approved) member gets their creation day.
- Blank for anyone not yet approved.
- Backfill for members already approved: the day of their approving review
  request; **blank** when there is none (bootstrapped admins, older imports).
- An admin may correct it.

---

## 2. Applications

### 2.1 The template

Admin-defined; one per purpose (a season registration, a selection trial, …),
not tied to an event. Stored in one `applications` table; the multilingual
text sits in JSON columns, so no further table is needed.

| field | notes |
|---|---|
| `languages` | `["en"]` or `["en", <one other>]`, e.g. `["en", "mr"]`; the other must be one of the club's languages (§1.2); any other is refused as not offered |
| `organisation` | the top line: the organisation the form is addressed to |
| `title` | e.g. "Training Camp & Selection Trial — Registration Form" |
| `subtitle` | optional, e.g. the affiliation line |
| `header` | optional list of short items: venue, dates, phone |
| `age_categories` | list of `{label, born_on_or_after?, born_on_or_before?, genders?}` |
| `selections` | optional list of texts ("Additional selections"), each printed with an empty checkbox the member ticks by hand (championship: "I will attend the daily practice sessions … 1st to 15th November") |
| `declaration` | text above the signatures |
| `form_footer` | optional closing line under the signatures (a slogan) |
| `terms` | optional list of `{heading, body}`, printed from page 2 |
| `terms_notes` | optional list of `{text, attribution?}`, boxed under the terms ("All participants are expected …", a motto) |
| `label_overrides` | optional: replace any standard label (§2.2) |
| `status` | `draft`, `saved` or `published` (§2.1.1) |
| `layout` | set by the server on save: the layout name and page 1's spacing (§2.4) |

| `facts` | the values that change each time, typed once: dates, date ranges, times, amounts, names (venue, city, phone), choices (on-ice / inline) |

Every printed text is a map of language code to text (`{"en": "...", "mr":
"..."}`), one editor input per print language; a header item may be a list
of them, one per line. The server refuses a `{"clause": …}` or `{"fact": …}`
reference (club_sdk 1.3.0, #342, #354): a library text (§2.2.1) is
inserted as its text. Any text may hold `{name}` gaps, `name` a lowercase
letter then lowercase letters, digits or `_` (any other brace text prints
as written); the server fills each from the fact of that name when it draws
the PDF, in each print language (#389, club_server#126).

#### Duplicate

An admin starts a new application as a copy of any earlier one (a draft
with its facts, age categories, clauses and custom text), then changes the
facts. This is the usual way to create one: last season's form with this
season's dates.

#### 2.1.1 States

The same lifecycle as an evaluation:

| move | from → to | what happens |
|---|---|---|
| create | → draft | editable; not shown to members |
| save | draft → saved | refused unless complete: title, declaration, footer line, every term, note and selection in every print language (header items and age-category names may stay English only), every `{gap}` names a fact of the template (`APPLICATION_UNKNOWN_FACT`, by place and language; a line of a multi-line header item is `header[i][j]`), and the form fits (§2.4). The layout is decided and stored. Read-only from here. |
| publish | saved → published | members see it and can download |
| unpublish | published → saved | members no longer see it |
| revert | saved → draft | editable again; the stored layout is dropped |

A published template is changed by unpublishing and reverting it. Only a
draft or saved template can be deleted (soft).

### 2.2 Standard labels

The form's fixed wording — section headings, field labels ("Full name",
"Date of birth" …), Male / Female / Other, the photo box, signature lines —
is the club's labels (club_server#133, club_client#396): seeded once from
the catalogue that ships with the server, then club data, each shown in the
club's languages and edited in the **Labels** card of Club details, after
the Library card. A language added in Profile options shows each label's
text in it blank (Required, in the error colour) until written there;
Finalize lists a label lacking a print language ("Label: Full name —
Hindi missing") and the server refuses it (`labels.<key>`). A language
removed is hidden, and its texts come back if it is added again.

The editor pre-fills each label for the chosen languages; an admin who
changes one for a single template stores it in `label_overrides`, which
then prints instead of the club's label.

#### 2.2.1 The clause library

Rules, declarations, header items, selections and closing notes come from
the club's library (#389, #396): club texts an admin adds, edits and
deletes in the **Library** card of Club details, after Profile options
(#399), each a kind (header, selection, declaration, rule, note), a short
name, its text in each of the club's languages with gaps allowed, and a
heading for a rule. The built-in clauses that ship with the server
(prototype: `clauses.json`) are seeded into it once (club_server#133), each
keeping its `key`; after that they are ordinary texts, edited and deleted
like any other. `GET /v1/applications/clauses` lists the same texts as the
library.

```json
"rule.matches": {"kind": "rule", "gaps": {"dates": "date_range", "venue": "name"},
  "heading": {"en": "Matches", "mr": "सामने", "hi": "मैच"},
  "text": {"en": "Tournament matches will take place from {dates} at {venue}.",
           "mr": "{dates} दरम्यान {venue} येथे स्पर्धेचे सामने होतील.", "hi": "…"}}
```

The editor lists the library's texts of each kind under a section's list,
each by its name, with no built-in or club split; tapping one inserts it
**as written**, in every print language, gaps included (`from {dates} at {venue}`), as a new
item that is then edited like any other: the admin renames a gap to the
fact it means (`{dates}` → `{match_dates}`), so two facts of one type can
serve two places. Nothing is filled when a text is inserted; a fact's
value prints wherever its gap stands, so changing a fact changes every
text using it. The State card lists each gap naming no fact before Save
("Selection 2 (Marathi): no fact named match_date") and Save stays off
while there is one; a (?) on the Facts heading explains facts with one
example of each type.

- **Gaps hold only dates, times, numbers and names — never nouns.** Marathi
  and Hindi inflect a noun inside a sentence (शिबिर → शिबिरातील, स्पर्धा →
  स्पर्धेतील), so where the noun changes the library has one clause per
  variant (`declaration.camp`, `.championship`, `.trial`), and the admin
  picks one.
- **Facts print in each language:** a date as "19 November 2026" / "19
  नोव्हेंबर 2026" / "19 नवंबर 2026" (month names in the library); a range as
  "1–15 November 2026" / "1 ते 15 नोव्हेंबर 2026"; a time with its part of the
  day ("6:00 am" / "सकाळी 6:00"); an amount with Indian grouping; choices
  joined with each language's "and". A name prints as typed, or as given for
  a language (`{"en": "Pune", "mr": "पुणे"}`).
- **Written text** (a rule, selection or note typed in each language) is
  there for anything the library lacks; save refuses one missing a print
  language. One that keeps coming back is added to the club's library.

The library's text taken from the club's existing paper form is word for word; each
clause's `_review` lists what still needs a fluent reader.

The prototype's catalogue: `labels.json`. Its Marathi is word for word from
the club's existing paper form wherever it has the label; each entry's `_review`
lists the languages written for the catalogue that still need a fluent
reader (Marathi for the new fields only; all Hindi).

### 2.3 Who sees what

- **Admin**: lists all in every state, creates, edits a draft, previews,
  moves it through its states, deletes (soft). Downloads the form of a
  published application for any member.
- **A member** (`registered`, `pending` or `approved`) **who has uploaded an
  identity document**: lists the published applications and downloads their
  own form. Without a document: none are offered.
- Rejected / disabled accounts: nothing.
- **Not eligible:** if the template has age categories and none matches the
  member (date of birth and gender), the download is refused with "not
  eligible for this application". A member with no date of birth is not
  eligible for a template with age categories.

No record is kept of who downloaded or handed in a form.

### 2.4 The PDF

Built by the server per request (fpdf2 with HarfBuzz text shaping; Lato
plus Noto Sans Devanagari, both OFL). A4, compact type (labels 7.5 pt,
values 9.5 pt). A field label prints as "English | other"; longer text
(heading, declaration, terms) prints in **one column per language**, side by
side.

Page 1 (the form; it fits one page in every case tried):

1. Logo (site media `logo`), then a column per language with organisation,
   title and subtitle; the header items in a shaded strip.
2. **Personal information** — full name; date of birth, member ID (username)
   and member since, in one row; gender (Male / Female / Other, "prefer not to
   say" ticks none); age group (every category, the matching one ticked).
   These sit beside a dashed passport-photo box (35 × 45 mm). Then address,
   phone, email, nationality, preferred language.
3. **Sports details** — club/district; preferred position (every club
   position, the member's ticked); past experience.
4. **Parent / guardian** — name, relation, phone, in one row. Printed for a
   member under 18 on the download day, or whenever a guardian is set.
5. **Additional selections**, if the template has any: an empty checkbox
   per item.
6. **Declaration**, then signature lines, left to right: **Date** (the
   download day in the club's time zone, which is the signing date),
   parent/guardian (when the guardian block is printed), player.
7. The template's `form_footer` line, in a shaded band.

Page 2: **terms**, if any, each rule's heading and text in the language
columns, then the `terms_notes` boxes. Printed double-sided, the application
is one sheet.

Every place to write is a dotted line set in from its label; a filled value
is printed on the first lines. Address and past experience get three lines,
the rest one. An answer always stays within its lines: it is set smaller
(down to 7 pt) and, only if it still does not fit, cut with "…". So the
layout depends on the template alone, never on a member's data.

**Fitting the form.** The server measures page 1 before drawing it and uses
the first of these layouts that fits:

1. **One page** — normal spacing, then spread to fill the page: the spare
   height is shared equally between every gap of page 1, without limit, in
   every layout, so page 1 always ends at the foot of the page.
2. **One page, tighter spacing** — closer lines and gaps (a few extra
   selections, a long declaration).
3. **Signing part on page 2** — page 1 holds the member's details (spread to
   fill it); additional selections, the declaration, the signatures and the
   footer line open page 2, and the terms follow them.

**Decided when the template is saved, not per download.** The layout depends
only on the template, so the server works it out when an admin saves one
(measuring takes 0.3–1.3 s, as long as drawing the PDF again) and stores it
on the template: the layout's name and page 1's spacing with and without the
guardian block, the one thing that varies by member. A download then draws
once (about 0.6–0.9 s) and the result is identical to measuring at download.
The editor shows which layout the form gets. The save is refused only when
the details alone cannot fit page 1 (dozens of age categories), saying by
how much.

The stored layout is worked out again for every template when the label
catalogue or the PDF fonts change (a server release that ships them). The
club logo is outside the template: a missing logo only shortens the header,
so the stored layout still fits.

When the extended profile is off its fields still print, as blanks. Footer:
member ID, download day, page n of N. Filename:
`application-<id>-<username>.pdf`. The app saves a member's form, their own
or one an admin fetches, as `<title> - <member's full name>.pdf` (the
username when the member has no name; club_client#404); the preview keeps
`<title>.pdf` and the blank form `<title> - blank form.pdf`.

**Preview.** An admin can preview a template in any state: the form drawn for
a fictional but believable demo member (Arjun Vikram Deshpande, `demo.player`:
every field filled as a real member would, a two-line address and past
experience, a guardian, the club's first position, a member-since date, born
well inside the first age category), with a light "PREVIEW" watermark and
"PREVIEW — not for submission" in the footer. There is no preview for a real
member: an admin downloads a real member's form of a published application
from that member's profile (Applications section). A draft's preview is measured on the spot; a saved
or published template's uses its stored layout, so it is exactly what members
will get.

**Blank form** (club_client#393, club_server#129). An admin can download a
saved or published template printed blank, to print and hand out to
applicants who cannot reach the app: no member's details and no watermark;
a published one carries "Form <publishId>". A draft has none (422
`APPLICATION_NOT_SAVED`). The editor shows **Download blank form** beside
Preview, greyed out with "Save the application first" on a draft; the PDF
goes to the app's `PdfAction` as "<title> - blank form.pdf".

### 2.5 API (server)

| method | path | who |
|---|---|---|
| GET | `/v1/applications` | members: published only; admins: all (`?status=`) |
| GET | `/v1/applications/{id}` | as above |
| POST | `/v1/applications` | admin (creates a draft) |
| PATCH | `/v1/applications/{id}` | admin, draft only |
| DELETE | `/v1/applications/{id}` | admin, draft or saved only |
| POST | `/v1/applications/{id}/save` · `/publish` · `/unpublish` · `/revert` | admin, the moves of §2.1.1 |
| GET | `/v1/applications/{id}/preview` | admin, any state: the sample member's form |
| GET | `/v1/applications/{id}/blank-form` | admin, saved or published: the form printed blank |
| GET | `/v1/applications/labels` | admin: the club's labels in its languages, to pre-fill the editor and for the Labels card |
| PATCH | `/v1/applications/labels/{key}` | admin: one label's text (English required) |
| GET | `/v1/applications/clauses` | admin: the club's library texts (the seeded built-ins among them), for the editor's lists |
| GET / POST | `/v1/applications/library` | admin: the club's library texts; add one |
| GET / PATCH / DELETE | `/v1/applications/library/{id}` | admin: one library text |
| POST | `/v1/applications/{id}/duplicate` | admin: a new draft copied from any application |
| GET | `/v1/applications/{id}/form` | the signed-in member, own form |
| GET | `/v1/applications/{id}/form/{username}` | admin |
| GET / PUT | `/v1/system/preferences/profile_options` | read: members; write: admin |

New error codes: application not found / not published, not eligible,
template incomplete (names the texts missing a language), unknown fact
(names each gap naming no fact, by place and language), library text not
found, label not found, language not offered (names the codes; shown inline
on the heading card and in the form that sent it), form does not fit,
invalid state move, identity document required (existing), applications
disabled.

---

## 3. App flow

- **Onboarding** (a member not yet approved cannot reach the member zone):
  after the identity document is uploaded the member lands on the waiting
  page. Its **Update profile** opens their own profile at
  `/onboarding/profile` (club_client#340): the profile's cards, each
  editable, the extended fields (sports details, background, guardian; each
  may be left blank) while the flag is on, and the Applications section.
  The waiting page lists the published applications, each with a Download
  button, and says: print it, affix a passport-size photograph, sign it and
  hand it in. Blank fields are filled in by hand.
- **Before a download**: a member's Download of their own form first asks
  "Is your profile complete?" (club_client#340), listing the printed fields
  blank on their profile (name, date of birth, gender, phone, email,
  address; with the extended profile on, its fields and, under 18, the
  guardian); with none blank it downloads without asking. Yes downloads; No opens
  their profile page (`/onboarding/profile` while pending, their own
  profile once active), or only closes the question on a profile page. An
  admin's preview, and an admin's download of a member's form, do not ask.
- **Member zone** (club_client#380): two sidebar items named
  **Applications**, as Reviews has. Under Main, beside Groups and Events,
  every member (admins included) sees the published ones they are eligible
  for, each with Download; one whose age categories they don't fit is not
  listed, and a member with no date of birth is asked to add one. The app
  works eligibility out itself from the template's age categories (the
  server's rule, R11); if that proves slow, the server will give it per
  listed application. Under Club Management, admins only, they see all
  with their state, Create, the editor, Preview and the state actions
  (Save, Publish, Unpublish, Revert), as on an evaluation.
- **Profile**: the three extended sections (hidden when the flag is off) and
  an Applications section to download from — on one's own profile, and for
  admins on any member's.

## 4. Work split

| # | repo | issue |
|---|---|---|
| 0 | — | Polish the prototype PDF (this step) |
| 1 | club_server | Extended profile fields, `profile_options`, membership date (+ backfill). Closes #3. |
| 2 | club_server | Applications: model, API, label catalogue, PDF, fonts, capability. Depends on 1. |
| 3 | club_sdk | Both: models, endpoints, capabilities, error codes, PDF bytes. |
| 4 | club_cli | Both: `users update` options, `profile-options get/set`, `applications list/show/create/update/delete/duplicate/save/publish/unpublish/revert/preview/labels/clauses/form`. |
| 5 | club_client | Extended profile: section forms (cl_club_forms), cards, the onboarding step (replaced by onboarding's profile page, club_client#340), Club Details options editor. |
| 6 | club_client | Applications: new `cl_club_applications` package, sidebar, list / editor / download, profile section, waiting-page list and text. |

### Client detail (issues 5–6)

- `cl_club_forms`: `UserSportsDetailsForm`, `UserBackgroundForm`,
  `UserGuardianForm`, `ProfileOptionsForm`, `ApplicationForm` (a text input
  per print language for each text; an age-category list editor; a terms
  list editor). SDK-free, `FormContract`.
- `cl_remote_store`: `clApplicationsMasterProvider`, `profileOptionsProvider`,
  `applicationLabelsProvider`; `capabilitiesProvider` gains the two flags.
- `cl_club_applications` (new): `ApplicationsView` (member list with
  Download; admin list with each state and Create), `ApplicationView`
  (admin editor, in sections, with Preview, Download blank form and the
  state actions),
  `ApplicationDownloadButton` (hands the PDF to the app's `PdfAction`:
  share, download or open by platform, club_client#324; also fetches a
  preview and a blank form).
- `cl_member_zone`: `ApplicationsScreen`, `ApplicationScreen`;
  `SidebarDestination.applications`; routes `/memberzone/applications` and
  `/memberzone/applications/:id`.
- `cl_member_onboarding`: the waiting page's application list and a
  pending member's profile page, which replaced the extended-fields step
  (club_client#340).

## 5. Open points from the prototype

1. The entries marked `_review` in `labels.json` and the sample template
   (Marathi for the new fields, the Marathi organisation and affiliation
   lines, all Hindi) await a fluent reader's review.
