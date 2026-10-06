/// The app's credit UI (club_core#101, #102): the reusable `CreditChip`,
/// the `CreditView` it opens, and `showCreditSheet`. A picker's "+" chip
/// (`CreditChip.add`) opens Add credit alone (club_client#41).
library;

export 'src/models/credit_grant_prefill.dart' show CreditGrantPrefill;
export 'src/views/credit_view.dart' show CreditView;
export 'src/widgets/credit_chip.dart' show CreditChip;
export 'src/widgets/credit_sheet.dart' show showCreditSheet;
