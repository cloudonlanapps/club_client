import 'package:cl_remote_store/cl_remote_store.dart'
    show ClPublicInquiryNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

/// Form → SDK adapter for the public inquiry form.
abstract final class InquiryFormSubmit {
  /// Submits what the form holds through [notifier].
  ///
  /// [phone], [answers] and [honeypot] are passed as the form holds them;
  /// each is sent as absent when empty. The phone is stored in international
  /// format, completed with [defaultCountryCode] when typed without a
  /// country code (#31).
  static Future<void> create({
    required ClPublicInquiryNotifier notifier,
    required String defaultCountryCode,
    required InquiryKind kind,
    required String name,
    required String email,
    required String message,
    required String token,
    required String phone,
    required Map<String, String> answers,
    required String honeypot,
  }) {
    return notifier.submit(
      kind: kind,
      name: name,
      email: email,
      message: message,
      token: token,
      phone: PhoneNumber.toInternationalOrNull(
        phone,
        defaultCountryCode: defaultCountryCode,
      ),
      extra: answers.isEmpty ? null : Map.of(answers),
      website: honeypot.isEmpty ? null : honeypot,
    );
  }
}
