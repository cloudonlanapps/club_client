/// Field-id constants of the `ShadForm` inside `InquiryForm`, which are also
/// the keys of the map its `validate()` returns.
class InquiryFormFields {
  InquiryFormFields._();

  /// The visitor's name (`String`, trimmed).
  static const String nameId = 'name';

  /// The visitor's email address (`String`, trimmed).
  static const String emailId = 'email';

  /// The visitor's phone number as typed (`String`, trimmed; empty when
  /// none).
  static const String phoneId = 'phone';

  /// The visitor's message (`String`, trimmed; empty when none).
  static const String messageId = 'message';

  /// The honeypot (`String`, as filled; empty for a person).
  static const String honeypotId = 'website';

  /// Key of the answers in the map `validate()` returns: a
  /// `Map<String, String>` of question key to the wire value picked, the
  /// unanswered questions left out. Not a field of its own; each question
  /// is the field [answerId] names.
  static const String answersId = 'answers';

  /// Starts the id of every question's field.
  static const String answerIdPrefix = 'answer:';

  /// The id of the select that answers the question with [key].
  static String answerId(String key) => '$answerIdPrefix$key';

  /// Lines the message field starts with.
  static const int messageMinLines = 4;

  /// Lines the message field grows to before it scrolls.
  static const int messageMaxLines = 6;
}
