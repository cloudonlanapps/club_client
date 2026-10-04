import 'package:club_sdk_2/club_sdk_2.dart' show CreditAccount;

/// The server's page cap on credit listings.
const creditPageSize = 50;

/// Credit usable on programme [eventId] for an enrollment that is a trial
/// or not (club_core#97, #105), as the server counts it
/// (`ensure_enrollment_credit`): usable accounts that are general or bound
/// to this programme, and whose trial flag matches — trial and ordinary
/// credit never mix (R53). At least 1 lets an accept, request, approve or
/// assign go through (R35).
int usableCreditsFor(
  Iterable<CreditAccount> accounts, {
  required int eventId,
  required bool trial,
}) => accounts
    .where(
      (a) =>
          a.usable &&
          a.isTrial == trial &&
          (a.eventId == null || a.eventId == eventId),
    )
    .fold<int>(0, (sum, a) => sum + a.balance);
