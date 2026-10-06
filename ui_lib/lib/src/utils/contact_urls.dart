import 'package:ui_lib/src/utils/phone_number.dart';

/// The links that reach a person: a call, a WhatsApp chat, an email.
///
/// Pure: each takes the value as it is stored and returns the URL to hand
/// to `launchContactUrl`.
abstract final class ContactUrls {
  /// Scheme of a call link.
  static const String callScheme = 'tel:';

  /// Scheme of an email link.
  static const String emailScheme = 'mailto:';

  /// Where a WhatsApp chat with a number opens.
  static const String whatsAppBase = 'https://wa.me/';

  /// A call link to [number], without the punctuation it is grouped with.
  static String call(String number) =>
      '$callScheme${number.replaceAll(PhoneNumber.grouping, '')}';

  /// A WhatsApp chat with [number], with no message filled in.
  ///
  /// WhatsApp takes the international number as digits only, so a number
  /// stored without a country code gets [defaultCountryCode] (digits only:
  /// `91`) in front.
  static String whatsApp(String number, {required String defaultCountryCode}) {
    final international = PhoneNumber.toInternational(
      number,
      defaultCountryCode: defaultCountryCode,
    );
    final digits = international.replaceAll(PhoneNumber.nonDigit, '');
    return '$whatsAppBase$digits';
  }

  /// An email link to [address], with [subject] when one is given.
  static String email(String address, {String? subject}) {
    if (subject == null || subject.isEmpty) return '$emailScheme$address';
    return '$emailScheme$address?subject=${Uri.encodeComponent(subject)}';
  }
}
