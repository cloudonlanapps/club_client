import 'package:cl_remote_store/src/models/contact_info.dart';
import 'package:club_sdk_2/club_sdk_2.dart';

/// The club's contact details from the server's public identity
/// (club_core#53), field by field over [fallback] — the host's bundled
/// block.
///
/// A field the server left out, or stored empty, keeps the bundled value,
/// so a club that has filled in a new phone number and nothing else gets
/// the new number and keeps everything else. The identity's `name` is the
/// club name; its `contact` block is the rest.
ContactInfo contactInfoFromServer(
  ClubIdentity identity, {
  required ContactInfo fallback,
}) {
  final contact = identity.contact ?? const ClubContactDetails();

  String? text(String? value) => value == null || value.isEmpty ? null : value;

  LocalizedText? Function() localized(
    LocalizedText? value,
    LocalizedText? or,
  ) =>
      () => value == null || ContactInfo.isBlank(value) ? or : value;

  String? Function() optional(String? value, String? or) =>
      () => text(value) ?? or;

  return fallback.copyWith(
    clubName: text(identity.name),
    phoneNumber: text(contact.phoneNumber),
    email: text(contact.email),
    whatsappNumber: optional(contact.whatsappNumber, fallback.whatsappNumber),
    whatsappMessage: localized(
      contact.whatsappMessage,
      fallback.whatsappMessage,
    ),
    emailSubject: localized(contact.emailSubject, fallback.emailSubject),
    tagline: localized(contact.tagline, fallback.tagline),
    addressLine1: localized(contact.address, fallback.addressLine1),
    addressLine2: localized(contact.addressLine2, fallback.addressLine2),
    city: localized(contact.city, fallback.city),
    state: localized(contact.state, fallback.state),
    postalCode: optional(contact.postalCode, fallback.postalCode),
    instagramUrl: optional(contact.instagramUrl, fallback.instagramUrl),
  );
}
