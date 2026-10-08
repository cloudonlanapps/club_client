/// The words of an `InquiryForm`: its labels, placeholders and messages.
///
/// The form has no text of its own: a club words its site, so the host
/// reads every string from the club's copy and hands it in.
class InquiryFormCopy {
  const InquiryFormCopy({
    required this.nameLabel,
    required this.namePlaceholder,
    required this.emailLabel,
    required this.emailPlaceholder,
    required this.phoneLabel,
    required this.phonePlaceholder,
    required this.messageLabel,
    required this.messagePlaceholder,
    required this.nameRequired,
    required this.emailRequired,
    required this.emailInvalid,
    required this.messageRequired,
  });

  /// Label of the name row, without a required mark: the row adds it.
  final String nameLabel;

  /// Placeholder of the name field.
  final String namePlaceholder;

  /// Label of the email row, without a required mark: the row adds it.
  final String emailLabel;

  /// Placeholder of the email field.
  final String emailPlaceholder;

  /// Label of the phone row.
  final String phoneLabel;

  /// Placeholder of the phone field.
  final String phonePlaceholder;

  /// Label of the message row, without a required mark: the row adds it
  /// when the message is required.
  final String messageLabel;

  /// Placeholder of the message field.
  final String messagePlaceholder;

  /// Shown on the name field when it is empty.
  final String nameRequired;

  /// Shown on the email field when it is empty.
  final String emailRequired;

  /// Shown on the email field when it does not hold an email address.
  final String emailInvalid;

  /// Shown on the message field when it is empty and a message is required.
  final String messageRequired;
}
