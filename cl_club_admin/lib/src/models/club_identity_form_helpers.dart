/// SDK adapter for `ClubIdentityForm` (club_core#20) — the one place that
/// bridges the form's flat `Map<String, dynamic>` and the SDK's
/// [ClubIdentity].
///
/// The form is SDK-free and speaks [FormTranslatedText]; this adapter maps
/// it to and from [LocalizedText], and turns an empty value into `null`, so
/// the field is left out of the stored document and its readers fall back
/// (the website to its bundled contact block, the server's email branding
/// to the deployment's name).
library;

import 'package:cl_club_forms/cl_club_forms.dart'
    show ClubIdentityForm, FormTranslatedText;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClClubIdentityMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ClubContactDetails, ClubIdentity, LocalizedText;

/// Builds the form's initial values from [identity] (empty when `null`).
Map<String, dynamic> buildClubIdentityFormInitialValues(
  ClubIdentity? identity,
) {
  final contact = identity?.contact;
  return {
    ClubIdentityForm.nameId: identity?.name ?? '',
    ClubIdentityForm.shortNameId: identity?.shortName ?? '',
    ClubIdentityForm.inquiryEmailId: identity?.inquiryEmail ?? '',
    ClubIdentityForm.phoneNumberId: contact?.phoneNumber ?? '',
    ClubIdentityForm.emailId: contact?.email ?? '',
    ClubIdentityForm.whatsappNumberId: contact?.whatsappNumber ?? '',
    ClubIdentityForm.postalCodeId: contact?.postalCode ?? '',
    ClubIdentityForm.instagramUrlId: contact?.instagramUrl ?? '',
    ClubIdentityForm.whatsappMessageId: formTranslatedTextOf(
      contact?.whatsappMessage,
    ),
    ClubIdentityForm.emailSubjectId: formTranslatedTextOf(
      contact?.emailSubject,
    ),
    ClubIdentityForm.taglineId: formTranslatedTextOf(contact?.tagline),
    ClubIdentityForm.addressId: formTranslatedTextOf(contact?.address),
    ClubIdentityForm.addressLine2Id: formTranslatedTextOf(
      contact?.addressLine2,
    ),
    ClubIdentityForm.cityId: formTranslatedTextOf(contact?.city),
    ClubIdentityForm.stateId: formTranslatedTextOf(contact?.state),
  };
}

/// [value] as the form edits it; `null` reads as empty.
FormTranslatedText formTranslatedTextOf(LocalizedText? value) => value == null
    ? const FormTranslatedText('')
    : FormTranslatedText(value.defaultValue, value.byLanguage);

/// [value] as the SDK stores it; empty reads as `null` (left out).
LocalizedText? localizedTextOf(Object? value) {
  final text = (value as FormTranslatedText?)?.trimmed();
  if (text == null || text.isEmpty) return null;
  return LocalizedText(text.defaultValue, text.byLanguage);
}

/// A trimmed text value, or `null` when empty.
String? textOf(Object? value) {
  final text = (value as String?)?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// The identity to store: [base] (what the server holds, read through
/// `getClubIdentity`) with every field the form edits replaced by [values].
/// Keys the model does not name — in the document and in its contact block
/// — are carried through. A contact block is written only when [base] has
/// one or the form fills one in.
ClubIdentity clubIdentityFromForm({
  required Map<String, dynamic> values,
  required ClubIdentity base,
}) {
  final contact = (base.contact ?? const ClubContactDetails()).copyWith(
    phoneNumber: () => textOf(values[ClubIdentityForm.phoneNumberId]),
    email: () => textOf(values[ClubIdentityForm.emailId]),
    whatsappNumber: () => textOf(values[ClubIdentityForm.whatsappNumberId]),
    whatsappMessage: () =>
        localizedTextOf(values[ClubIdentityForm.whatsappMessageId]),
    emailSubject: () =>
        localizedTextOf(values[ClubIdentityForm.emailSubjectId]),
    tagline: () => localizedTextOf(values[ClubIdentityForm.taglineId]),
    address: () => localizedTextOf(values[ClubIdentityForm.addressId]),
    addressLine2: () =>
        localizedTextOf(values[ClubIdentityForm.addressLine2Id]),
    city: () => localizedTextOf(values[ClubIdentityForm.cityId]),
    state: () => localizedTextOf(values[ClubIdentityForm.stateId]),
    postalCode: () => textOf(values[ClubIdentityForm.postalCodeId]),
    instagramUrl: () => textOf(values[ClubIdentityForm.instagramUrlId]),
  );
  final writeContact =
      base.contact != null || contact != const ClubContactDetails();
  return base.copyWith(
    name: () => textOf(values[ClubIdentityForm.nameId]),
    shortName: () => textOf(values[ClubIdentityForm.shortNameId]),
    inquiryEmail: () => textOf(values[ClubIdentityForm.inquiryEmailId]),
    contact: () => writeContact ? contact : null,
  );
}

class ClubIdentityFormSubmit {
  const ClubIdentityFormSubmit._();

  /// Save the whole identity from the form's [values], over [base] (the
  /// master's read), in one write. Rethrows a refusal.
  static Future<ClubIdentity> update({
    required Map<String, dynamic> values,
    required ClubIdentity base,
    required ClClubIdentityMasterNotifier notifier,
  }) {
    return notifier.save(clubIdentityFromForm(values: values, base: base));
  }
}
