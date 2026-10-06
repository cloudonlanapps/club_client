import 'package:club_sdk_2/club_sdk_2.dart' show Inquiry;

/// What an admin's emailed reply to an inquiry starts with.
abstract final class InquiryReply {
  /// Key of the subject a form sent among the inquiry's `extra` answers.
  static const String subjectKey = 'subject';

  /// What a reply's subject starts with.
  static const String replyPrefix = 'Re: ';

  /// The reply's subject, `Re: <subject>`, or null when the form sent no
  /// subject with [inquiry].
  static String? subject(Inquiry inquiry) {
    final sent = inquiry.extra?[subjectKey];
    if (sent is! String || sent.trim().isEmpty) return null;
    return '$replyPrefix${sent.trim()}';
  }
}
