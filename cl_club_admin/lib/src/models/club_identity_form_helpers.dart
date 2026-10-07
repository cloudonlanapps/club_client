/// SDK adapter for the club identity section forms (`ClubDetailsForm`,
/// `ClubContactForm`, `ClubAddressForm`; club_core#20) — the one place that
/// bridges the forms' flat `Map<String, dynamic>` and the SDK's
/// [ClubIdentity].
///
/// The forms are SDK-free and speak [FormTranslatedText]; this adapter maps
/// it to and from [LocalizedText], and turns an empty value into `null`, so
/// the field is left out of the stored document and its readers fall back
/// (the website to its bundled contact block, the server's email branding
/// to the deployment's name).
///
/// The server stores the identity as one document and replaces it whole on
/// every write, so a section is saved as the stored document with that
/// section's fields replaced: each `…FromForm` starts from `base`, the
/// master's read, and touches its own fields only.
library;

import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ClubAddressFormFields,
        ClubContactFormFields,
        ClubDetailsFormFields,
        FormTranslatedText;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClClubIdentityMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ClubContactDetails, ClubIdentity, LocalizedText;

/// Builds the initial values of the three section forms from [identity]
/// (empty when `null`); each form reads the keys of its own fields.
Map<String, dynamic> buildClubIdentityFormInitialValues(
  ClubIdentity? identity,
) {
  final contact = identity?.contact;
  return {
    ClubDetailsFormFields.nameId: identity?.name ?? '',
    ClubDetailsFormFields.shortNameId: identity?.shortName ?? '',
    ClubDetailsFormFields.taglineId: formTranslatedTextOf(contact?.tagline),
    ClubDetailsFormFields.inquiryEmailId: identity?.inquiryEmail ?? '',
    ClubContactFormFields.phoneNumberId: contact?.phoneNumber ?? '',
    ClubContactFormFields.whatsappNumberId: contact?.whatsappNumber ?? '',
    ClubContactFormFields.whatsappMessageId: formTranslatedTextOf(
      contact?.whatsappMessage,
    ),
    ClubContactFormFields.emailId: contact?.email ?? '',
    ClubContactFormFields.emailSubjectId: formTranslatedTextOf(
      contact?.emailSubject,
    ),
    ClubContactFormFields.instagramUrlId: contact?.instagramUrl ?? '',
    ClubAddressFormFields.addressId: formTranslatedTextOf(contact?.address),
    ClubAddressFormFields.addressLine2Id: formTranslatedTextOf(
      contact?.addressLine2,
    ),
    ClubAddressFormFields.cityId: formTranslatedTextOf(contact?.city),
    ClubAddressFormFields.stateId: formTranslatedTextOf(contact?.state),
    ClubAddressFormFields.postalCodeId: contact?.postalCode ?? '',
  };
}

/// The language codes [identity] already holds a translation in, across
/// every translatable field, in alphabetical order: the languages the
/// section forms offer.
List<String> clubIdentityLanguagesOf(ClubIdentity? identity) {
  final contact = identity?.contact;
  final translated = [
    contact?.tagline,
    contact?.whatsappMessage,
    contact?.emailSubject,
    contact?.address,
    contact?.addressLine2,
    contact?.city,
    contact?.state,
  ];
  return {for (final text in translated) ...?text?.byLanguage.keys}.toList()
    ..sort();
}

/// [value] as the forms edit it; `null` reads as empty.
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

/// [base] with its contact block replaced by [contact]. A contact block is
/// written only when [base] has one or [contact] holds something.
ClubIdentity clubIdentityWithContact(
  ClubIdentity base,
  ClubContactDetails contact,
) {
  final writeContact =
      base.contact != null || contact != const ClubContactDetails();
  return base.copyWith(contact: () => writeContact ? contact : null);
}

/// The identity to store after the Club section is saved: [base] (what the
/// server holds, read through `getClubIdentity`) with the name, short name,
/// inquiry email and tagline replaced by [values]. Every other field, and
/// every key the model does not name, is carried through.
ClubIdentity clubDetailsFromForm({
  required Map<String, dynamic> values,
  required ClubIdentity base,
}) {
  final contact = (base.contact ?? const ClubContactDetails()).copyWith(
    tagline: () => localizedTextOf(values[ClubDetailsFormFields.taglineId]),
  );
  return clubIdentityWithContact(base, contact).copyWith(
    name: () => textOf(values[ClubDetailsFormFields.nameId]),
    shortName: () => textOf(values[ClubDetailsFormFields.shortNameId]),
    inquiryEmail: () => textOf(values[ClubDetailsFormFields.inquiryEmailId]),
  );
}

/// The identity to store after the Contact section is saved: [base] with
/// the phone, WhatsApp, email and Instagram fields of its contact block
/// replaced by [values]. Everything else is carried through.
ClubIdentity clubContactFromForm({
  required Map<String, dynamic> values,
  required ClubIdentity base,
}) {
  final contact = (base.contact ?? const ClubContactDetails()).copyWith(
    phoneNumber: () => textOf(values[ClubContactFormFields.phoneNumberId]),
    whatsappNumber: () =>
        textOf(values[ClubContactFormFields.whatsappNumberId]),
    whatsappMessage: () =>
        localizedTextOf(values[ClubContactFormFields.whatsappMessageId]),
    email: () => textOf(values[ClubContactFormFields.emailId]),
    emailSubject: () =>
        localizedTextOf(values[ClubContactFormFields.emailSubjectId]),
    instagramUrl: () => textOf(values[ClubContactFormFields.instagramUrlId]),
  );
  return clubIdentityWithContact(base, contact);
}

/// The identity to store after the Address section is saved: [base] with
/// the address fields of its contact block replaced by [values]. Everything
/// else is carried through.
ClubIdentity clubAddressFromForm({
  required Map<String, dynamic> values,
  required ClubIdentity base,
}) {
  final contact = (base.contact ?? const ClubContactDetails()).copyWith(
    address: () => localizedTextOf(values[ClubAddressFormFields.addressId]),
    addressLine2: () =>
        localizedTextOf(values[ClubAddressFormFields.addressLine2Id]),
    city: () => localizedTextOf(values[ClubAddressFormFields.cityId]),
    state: () => localizedTextOf(values[ClubAddressFormFields.stateId]),
    postalCode: () => textOf(values[ClubAddressFormFields.postalCodeId]),
  );
  return clubIdentityWithContact(base, contact);
}

/// Saves one section of the club's identity. Each method writes `base`, the
/// master's read, with that section's fields replaced by the form's values,
/// and rethrows a refusal.
class ClubIdentityFormSubmit {
  const ClubIdentityFormSubmit._();

  /// Save the Club section: name, short name, tagline, inquiry email.
  static Future<ClubIdentity> updateClub({
    required Map<String, dynamic> values,
    required ClubIdentity base,
    required ClClubIdentityMasterNotifier notifier,
  }) => notifier.save(clubDetailsFromForm(values: values, base: base));

  /// Save the Contact section: phone, WhatsApp, email, Instagram.
  static Future<ClubIdentity> updateContact({
    required Map<String, dynamic> values,
    required ClubIdentity base,
    required ClClubIdentityMasterNotifier notifier,
  }) => notifier.save(clubContactFromForm(values: values, base: base));

  /// Save the Address section: address lines, city, state, postal code.
  static Future<ClubIdentity> updateAddress({
    required Map<String, dynamic> values,
    required ClubIdentity base,
    required ClClubIdentityMasterNotifier notifier,
  }) => notifier.save(clubAddressFromForm(values: values, base: base));
}
