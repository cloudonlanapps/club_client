# cl_club_credits

## Credit UI (cl_club_credits)

Credit has exactly two UI pieces (#101, #102):

- **`CreditChip`** — a member's usable credit as a coin and a number. It
  renders nothing unless `creditSystemProvider` is `true` (never guess; no
  credit call otherwise). Tapping it opens the member's `CreditView` in a
  full-height `ShadSheet` (`showCreditSheet`): a modal the chip opens, so no
  route plumbing, and it works over dialogs. `CreditChip.add`, the "+" chip
  of a member a picker cannot fund, does **not** open the sheet: it opens Add
  credit alone in a dialog over the picker (`showCreditGrantDialog`),
  pre-filled with the programme and trial flag (club_client#41). Only an
  admin may add credit, so "+" renders nothing for anyone else: an organizer
  who is not an admin sees the number chip alone (club_client#49). In the
  pickers (Assign Users, Assign Trial) a member with no usable credit shows
  two chips side by side: the coin and `0` (a number chip, so it opens the
  sheet) and then, for an admin, "+". A funded member shows the number chip only; once "+"
  is saved the row turns into that form.
- **`CreditView`** — usable total, packages, statement (server `totalAfter`,
  never recomputed), and admin-only actions. `/memberzone/credit/:username`
  (`CreditScreen`) mounts it only for the `credit.released` deep link.

Credit actions open in place (club_client#41): Add credit, Extend, Reverse and
Transfer show their form inside the view (`CreditActionForm.inPlace` in a
`CreditActionPanel`, with Cancel and Save) in place of the packages and the
statement, which return when the form closes. The view pushes no dialog and
opens nothing when it mounts, so from a chip inside a dialog the deepest stack
is that dialog and the sheet. `CreditActionForm` is the one connected host of
the four `cl_club_forms` credit forms; `CreditActionDialog` hosts Add credit for the "+"
chip only.

Rules: actions credit forbids are greyed out up front — `ActionItem.reason`
carries the chip beside the disabled action — never tried and then shown as
an error (catch-and-toast stays as the safety net). Programmes only. The
funding rule mirrors the server: usable general or this-programme credit
with a matching trial flag (`usableCreditsFor`). The app never sends
`creditDisposition`: programme credit is settled in the credit view first.

State: masters in cl_remote_store (`clCreditAccountsMasterProvider`,
`clCreditEntriesMasterProvider`, `clEventCreditRosterProvider`,
`clUsableCreditAccountsProvider`) plus derived providers; anything that moves
credit (credit actions, marks, leave decisions, enrollment changes) bumps
`creditsVersion`, which every credit provider watches.
