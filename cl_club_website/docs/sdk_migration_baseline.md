# Baseline: the site before the club_core SDK switch

> **History.** Written in a club's site repo while the site moved onto club_core's
> SDK, when the site's code lived there under `app/` and `club_website/`. That
> code is this package now (#52); the paths below are as they were then, and
> `scripts/capture_pages` is in that repo's history, not here.

Captured with `scripts/capture_pages` against a release web build of the site
as it stood at the branch point — the site's own `club_sdk_2` copy, `cl_users`
still present, every provider served from `app/lib/stub_overrides.dart`.

There are no automated tests for the rendered pages (`app/` and `club_website/`
have zero test files between them), and the site will not compile part-way
through the model changes, so this is the reference the whole migration is
checked against: one look at the end, not a look after each commit.

## How it was taken

```bash
just build
scripts/capture_pages --out <dir> \
    --static-dir ../../p52icehockyclub_website_static_data/static \
    --camp-id 1 --programme-id 4 --one-off-id 2 --venue-id 1
```

**`--static-dir` is history.** That checkout was archived and deleted once the
server began serving media by uuid; captures after step 3 pass no `--static-dir`
at all, and the note the tool prints about `/static/` placeholders is expected.
The tree now lives in the backup at
`p52club_website_seed_backup/preserve/`.

`--static-dir` serves the media tree at `/static/` from the same origin, the
way nginx does in production. Without it every `/static/` image resolves to
the SPA's index.html, fails to decode, and the page comes back full of
placeholders — which is how the first attempt at this baseline was taken, and
why it is worth naming.

The 11 public routes, at 1440×2400, with `/public/events/:id` taken three
times — the three event types share one route and render very different pages:

| # | route | page |
|---|---|---|
| 00 | `/` | landing |
| 01 | `/public/about-us` | The Club |
| 02 | `/public/programs` | Training Sessions |
| 03 | `/public/events` | Learning Camps |
| 04 | `/public/events/1` | camp detail |
| 05 | `/public/events/4` | programme detail |
| 06 | `/public/one-off` | Club Events |
| 07 | `/public/events/2` | one-off detail |
| 08 | `/public/coaches` | Ice Masters |
| 09 | `/public/rinks` | The Rinks |
| 10 | `/public/rink/1` | rink detail |
| 11 | `/public/contact-us` | Contact Us |
| 12 | `/auth/signup` | Coming Soon |

The programme page is the one that matters most: it is the only one carrying
the batch timings table, the fee structure, the packages and the facilities,
and site#8 and site#12 rewrite all of them.

The capture was taken with site#14 already applied. That deletion cannot move
a public page — `ENABLE_PRIVATE_FEATURES` was never set, so every widget it
touched already rendered its disabled branch — and the pre-#14 shots of the
other routes are identical.

## What the baseline shows, and what is not a regression

**Coach avatars and venue images become placeholders, and stay that way.**
They are server media now, addressed by uuid, and no uuids exist until the
coaches' avatars and the rink photo are uploaded to the new server. site#3 and
site#13 both say so: the fixtures carry `null` and the placeholder renders.
Those are the two differences that are expected and not regressions.

**Event card and gallery images still come from `/static/`** in the baseline
and are captured, so they are a fair comparison.

**The landing carousel is mid-transition** in the capture. It auto-advances,
so the shot catches whatever frame the virtual-time budget lands on and two
slides can overlap. Not a rendering fault, and not stable between runs —
compare the page chrome and the card contents, not the carousel frame.

**Times render in the club's timezone.** Since site#8 the timetable is derived
from each event's UTC window rather than read from server-sent text, so the
capture pins `TZ` to `Asia/Kolkata`; a capture host running in UTC would show
every session five and a half hours early.

## Fixture ids at the branch point

The detail routes need an id and the fixtures decide them. Integer ids here;
site#9 turns them into public id strings, so the equivalent later capture uses
a different value for the same event.

| id | type | title |
|---|---|---|
| 1 | camp | Learn to Play Camp 2025 |
| 2 | oneOff | Special Training Session with a Guest Coach |
| 3 | oneOff | Meet & Greet with a Guest Player |
| 4 | programme | Weekday Training - Batch 3 |
| 5 | programme | Weekend Training - Batch 2 |
| 6 | programme | Weekend Training - Batch 1 |
| 8 | camp | Training Camp & Team Selection Trials 2026 |
| 9 | camp | Learn to Play Camp 2026 |

Venue 1 is the only venue.

## Step 2 — the same pages on club_core's SDK, still offline

Every one of the 11 routes renders, on bundled fixtures, with no server. What
differs from the baseline, and why:

**Media that is the server's is missing, and stays missing.** Coach avatars,
event covers and gallery images, and the venue photo are all addressed by
media uuid now, and no uuids exist until the images are uploaded to the new
server. Every one renders its placeholder. site#3, site#12 and site#13 each
say so; it is the stub build's honest state, not a regression.

**Site chrome is no longer missing.** The landing background and every content
page's hero are bundled assets since site#5, so they render with nothing
serving `/static/` at all — which the baseline could not do.

**Event card paragraphs are longer.** The old model had three text fields —
a tagline, a card paragraph and a long description. club_core has two:
`marketing.shortDescription` and `description`. The tagline keeps the italic
line under the title and `description` carries the long form, so a card shows
the long text where it used to show a middle-length one.

**Times are the club's published times.** The captured windows disagreed with
the captured timing text; the text was right, and the windows are corrected to
match. See the commit "Correct the fixture event windows".

**"For ages 5+" is derived, not quoted.** The free-text age range is gone from
the model; eligibility is a gender and two dates of birth. Every captured
event that named one said "5+", so the fixtures carry a date-of-birth cutoff
five years before each event's own start, and the phrase is computed from it.

**Camp 1's hero shows one timing line, not two.** Its two "batches" were
parallel morning groups, which the new server does not model — those are
separate camps now. See site#8.

**The contact page's map is blank** in both captures. It is a Google Maps
iframe and the capture has no network. Not something these changes touch.

## Step 4 — parity, against a real server

Same 11 routes, same capture, now against a seeded `club_server`:

```bash
just server-start && just restore
CLUB_API_BASE_URL=http://127.0.0.1:8310/v1 just build
scripts/capture_pages --out <dir> --camp-id … --programme-id … --one-off-id … --venue-id …
```

Public ids change with the deployment, because they are HMACs of the row id
keyed by the server's secret. Read them off `/public/events` and
`/public/venues` before capturing.

**The media the baseline had is back, from the server.** Coach avatars, event
covers and galleries, and the venue photo all resolve by uuid. The camp detail
page's gallery, the event cards' images and the rink hero match the baseline.

**Two things read better than the baseline.**

The camp's hero timings show "7:30 AM – 9:00 AM Morning Batch, 9:00 AM –
10:00 AM Late Morning Batch" — the server's own sessions, two sequential named
slots. The offline fixtures had collapsed that camp into one slot because its
captured "batches" overlapped in time; the seeded data does not, so the
timetable is the real one.

Every content page has a hero. In the baseline a page with no `/static/` image
rendered no hero at all — no badge, no title, no description — because the
whole section was gated on having a picture.

**Two things are unchanged and expected.** The contact page's map is a Google
Maps iframe and stays blank in a capture with no external network. The landing
hero shows its loading placeholder: the page mounts the inline player and the
browser does fetch the video from the API — the server log shows the 206 probe
and the 200 stream — but 44MB does not decode inside a headless screenshot's
budget. It is the one thing on the site a still capture cannot show; look at it
in `just run-live`.

## Step 5: the media descriptor (club_server#424)

The step-4 capture had a hole the notes above understate. The public surface
published bare media uuids, and a download URL addresses media by uuid and
ends in `/download`, so nothing in a response or a URL said what a file was.
Every renderer the site has decides by file extension. So:

* the landing hero showed a broken-image glyph, not a video;
* four of the sixteen items in the camp gallery — the videos — were blank;
* the selection trials' PDF had no page preview.

The site worked around it with `mediaKindProvider`: one `Range: bytes=0-0`
request per media item on every page that showed any, just to read the
`Content-Type` back. That is gone. The server now publishes a descriptor —
`{ uuid, mediaType, mimeType, filename, availableVariants }` — everywhere it
published a uuid, including `siteMedia`, which is where the landing hero
lives, and the download route takes the filename as a trailing path segment
so the URL ends in a real extension.

Four repositories moved together:

| repo | PR | what |
|---|---|---|
| club_server | #425 | the descriptor, the filename route, HEAD |
| club_core | #42 | `MediaRef`, and the URL builder the site was duplicating |
| the CLI | #30 | filename-bearing URLs; the type in seed output |
| cl_video_player | #9 | `GalleryItem.previewUrl` — a preview cannot be derived |

That last one is the subtle half. The *type* questions (`isVideoUrl` and
friends) fix themselves once the URL carries an extension. The *preview*
questions do not: `getPosterUrl` rewrites `clip.mp4` into a sibling
`clip_poster.webp`, and the server keeps a preview at the same address under
`?variant=poster`. The derived path 404s, which is why every thumbnail in a
mixed gallery was blank even where the type was right.

### Verified

Captured against the seeded stack on 8310, with the site built at
`CLUB_API_BASE_URL=http://127.0.0.1:8310/v1`:

* **the landing hero plays** — the capture shows a frame of the club video
  with the inline mute control, where step 4 could only show a placeholder;
* **the camp gallery** shows twelve photos and four video posters with play
  buttons;
* **the selection trials' PDF** shows its first page, the PDF badge and the
  download button;
* coach avatars, event covers and the venue photo are unchanged.

No reseed was needed: the descriptors are computed from the media rows the
step-4 seed already wrote.
