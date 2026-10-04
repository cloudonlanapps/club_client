import 'package:cl_remote_store/cl_remote_store.dart'
    show ClCreditAccountsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart'
    show CreditAccount, CreditTransferResult;
import 'package:ui_lib/ui_lib.dart' show CreditFormFields, CreditGrantForm;

/// SDK ↔ credit form adapter (club_core#101): the forms speak flat values
/// with local dates; the SDK takes UTC instants and typed arguments.

/// Initial values for Add credit: general unless [programmeId], trial when
/// [trial] (the pickers pre-fill both, club_core#105).
Map<String, dynamic> buildCreditGrantFormInitialValues({
  required DateTime today,
  int? programmeId,
  bool trial = false,
}) => CreditGrantForm.defaultValues(
  today: today,
  programmeId: programmeId,
  trial: trial,
);

/// A validity start: the local day's first instant, as UTC.
DateTime creditValidFromUtc(DateTime localDay) =>
    DateTime(localDay.year, localDay.month, localDay.day).toUtc();

/// A validity end: the local day's last second, as UTC, so the day picked is
/// the last day the credit can be used.
DateTime creditValidUntilUtc(DateTime localDay) =>
    DateTime(localDay.year, localDay.month, localDay.day, 23, 59, 59).toUtc();

/// Form → SDK for the credit actions, through the member's accounts master.
class CreditAccountFormSubmit {
  CreditAccountFormSubmit._();

  static Future<CreditAccount> openAccount({
    required Map<String, dynamic> values,
    required ClCreditAccountsMasterNotifier notifier,
  }) {
    final programme = values[CreditFormFields.programmeId] as int;
    return notifier.openAccount(
      credits: values[CreditFormFields.creditsId] as int,
      validFromUtc: creditValidFromUtc(
        values[CreditFormFields.validFromId] as DateTime,
      ),
      validUntilUtc: creditValidUntilUtc(
        values[CreditFormFields.validUntilId] as DateTime,
      ),
      reason: values[CreditFormFields.reasonId] as String,
      eventId: programme == CreditFormFields.generalProgramme
          ? null
          : programme,
      isTrial: values[CreditFormFields.trialId] as bool,
    );
  }

  static Future<CreditAccount> extendValidity(
    String accountId, {
    required Map<String, dynamic> values,
    required ClCreditAccountsMasterNotifier notifier,
  }) => notifier.extendValidity(
    accountId,
    validUntilUtc: creditValidUntilUtc(
      values[CreditFormFields.validUntilId] as DateTime,
    ),
    reason: values[CreditFormFields.reasonId] as String,
  );

  static Future<CreditAccount> reverseGrant(
    String accountId, {
    required Map<String, dynamic> values,
    required ClCreditAccountsMasterNotifier notifier,
  }) => notifier.reverseGrant(
    accountId,
    credits: values[CreditFormFields.creditsId] as int,
    reason: values[CreditFormFields.reasonId] as String,
  );

  static Future<CreditTransferResult> transfer(
    String accountId, {
    required Map<String, dynamic> values,
    required ClCreditAccountsMasterNotifier notifier,
  }) => notifier.transfer(
    accountId,
    penalty: values[CreditFormFields.penaltyId] as int,
    validFromUtc: creditValidFromUtc(
      values[CreditFormFields.validFromId] as DateTime,
    ),
    validUntilUtc: creditValidUntilUtc(
      values[CreditFormFields.validUntilId] as DateTime,
    ),
    reason: values[CreditFormFields.reasonId] as String,
  );
}
