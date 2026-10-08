import 'package:cl_club_forms/cl_club_forms.dart'
    show InquiryFormCopy, InquiryFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClPublicInquiryNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind, ServerException;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

import '../l10n/site_strings.dart';

/// A required mark at the end of a label, as a club's copy may write one
/// (`Name *`).
final RegExp inquiryLabelRequiredMark = RegExp(r'\s*\*\s*$');

/// [label] without a required mark at its end. The form marks the rows it
/// requires itself, so a mark in the club's copy would show twice, or on a
/// row the form does not require.
String inquiryLabelWithoutMark(String label) =>
    label.replaceFirst(inquiryLabelRequiredMark, '');

/// The wording of the inquiry form, from the site's copy: the labels and
/// messages every inquiry form shares from [strings], and the message row's
/// own [messageLabel] and [messagePlaceholder].
InquiryFormCopy buildInquiryFormCopy({
  required SiteStrings strings,
  required String messageLabel,
  required String messagePlaceholder,
}) => InquiryFormCopy(
  nameLabel: inquiryLabelWithoutMark(strings.contactFormNameLabel),
  namePlaceholder: strings.contactFormNamePlaceholder,
  emailLabel: inquiryLabelWithoutMark(strings.contactFormEmailLabel),
  emailPlaceholder: strings.contactFormEmailPlaceholder,
  phoneLabel: inquiryLabelWithoutMark(strings.contactFormPhoneLabel),
  phonePlaceholder: strings.contactFormPhonePlaceholder,
  messageLabel: inquiryLabelWithoutMark(messageLabel),
  messagePlaceholder: messagePlaceholder,
  nameRequired: strings.contactFormErrorRequired,
  emailRequired: strings.contactFormErrorRequired,
  emailInvalid: strings.contactFormErrorEmail,
  messageRequired: strings.contactFormErrorRequired,
);

/// Form → SDK adapter for the public inquiry form.
abstract final class InquiryFormSubmit {
  /// The status the server refuses with when one visitor sends too many.
  static const int rateLimitedStatus = 429;

  /// Submits [values], the map `InquiryForm.validate()` returned, through
  /// [notifier].
  ///
  /// The phone, the answers and the honeypot are each sent as absent when
  /// empty. The phone is stored in international format, completed with
  /// [defaultCountryCode] when typed without a country code (#31).
  static Future<void> create({
    required ClPublicInquiryNotifier notifier,
    required String defaultCountryCode,
    required InquiryKind kind,
    required String token,
    required Map<String, dynamic> values,
  }) {
    final answers = values[InquiryFormFields.answersId] as Map<String, String>;
    final honeypot = values[InquiryFormFields.honeypotId] as String;
    return notifier.submit(
      kind: kind,
      name: values[InquiryFormFields.nameId] as String,
      email: values[InquiryFormFields.emailId] as String,
      message: values[InquiryFormFields.messageId] as String,
      token: token,
      phone: PhoneNumber.toInternationalOrNull(
        values[InquiryFormFields.phoneId] as String,
        defaultCountryCode: defaultCountryCode,
      ),
      extra: answers.isEmpty ? null : Map.of(answers),
      website: honeypot.isEmpty ? null : honeypot,
    );
  }

  /// What to tell the visitor when sending failed with [error]: fixed text
  /// from [strings], never the error itself.
  static String refusalMessage(Object error, SiteStrings strings) =>
      error is ServerException && error.statusCode == rateLimitedStatus
      ? strings.contactFormErrorRateLimited
      : strings.contactFormErrorGeneric;
}
