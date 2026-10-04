# cl_club_credits

The app's credit UI, which is exactly two pieces (club_core#101, #102):

- **`CreditChip`** — a member's usable credit as a coin and a number. It
  renders nothing unless the server reports the credit system on, and tapping
  it opens that member's credit view in a sheet. It is used wherever credit
  matters, including beside an action greyed out for lack of credit.
- **`CreditView`** — the member's packages (accounts), their statement with
  the server's running total, and, for admins, add credit, extend, reverse and
  transfer. Opened in a sheet by the chip (`showCreditSheet`), or mounted by
  `CreditScreen` in `cl_member_zone` for a notification deep link.

SDK access goes through `cl_remote_store` (`clCreditAccountsMasterProvider`,
`clCreditEntriesMasterProvider`, `clMemberCreditTotalProvider`); the forms are
SDK-free in `ui_lib`.
