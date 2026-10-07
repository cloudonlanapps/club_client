/// Field ids shared by the credit forms (club_core#101). The flat value maps
/// the forms return are keyed by these.
class CreditFormFields {
  const CreditFormFields._();

  static const String creditsId = 'credits';
  static const String validFromId = 'validFrom';
  static const String validUntilId = 'validUntil';
  static const String programmeId = 'programme';
  static const String trialId = 'trial';
  static const String reasonId = 'reason';
  static const String penaltyId = 'penalty';

  /// The programme select's value for a general (unbound) account.
  static const int generalProgramme = 0;

  /// The penalty a transfer starts with, and the least it may be.
  static const int noPenalty = 0;
}
