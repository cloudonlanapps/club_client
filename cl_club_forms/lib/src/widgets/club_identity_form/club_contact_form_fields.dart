/// Field-id constants and labels of the `ShadForm` inside `ClubContactForm`.
class ClubContactFormFields {
  ClubContactFormFields._();

  /// The club's phone number, in E.164.
  static const String phoneNumberId = 'phoneNumber';

  /// The number WhatsApp links use, in E.164.
  static const String whatsappNumberId = 'whatsappNumber';

  /// The text a WhatsApp link starts with; translatable.
  static const String whatsappMessageId = 'whatsappMessage';

  /// The club's public email address.
  static const String emailId = 'email';

  /// The subject an email link starts with; translatable.
  static const String emailSubjectId = 'emailSubject';

  /// The link to the club's Instagram page.
  static const String instagramUrlId = 'instagramUrl';

  /// Label of [phoneNumberId].
  static const String phoneNumberLabel = 'Phone';

  /// Label of [whatsappNumberId].
  static const String whatsappNumberLabel = 'WhatsApp number';

  /// Label of [whatsappMessageId].
  static const String whatsappMessageLabel = 'WhatsApp message';

  /// Label of [emailId].
  static const String emailLabel = 'Email';

  /// Label of [emailSubjectId].
  static const String emailSubjectLabel = 'Email subject';

  /// Label of [instagramUrlId].
  static const String instagramUrlLabel = 'Instagram link';

  /// Help under [whatsappNumberId].
  static const String whatsappNumberHelp =
      'Left empty, WhatsApp links use the phone.';

  /// Every field's label, in the order the form shows them.
  static const Map<String, String> labels = {
    phoneNumberId: phoneNumberLabel,
    whatsappNumberId: whatsappNumberLabel,
    whatsappMessageId: whatsappMessageLabel,
    emailId: emailLabel,
    emailSubjectId: emailSubjectLabel,
    instagramUrlId: instagramUrlLabel,
  };

  /// The plain text fields; each value is a `String`.
  static const List<String> textIds = [
    phoneNumberId,
    whatsappNumberId,
    emailId,
    instagramUrlId,
  ];

  /// The translatable fields; each value is a `FormTranslatedText`.
  static const List<String> translatedIds = [whatsappMessageId, emailSubjectId];
}
