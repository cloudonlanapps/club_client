/// Field ids of `ApplicationLabelForm` (club_client#396), and the key of
/// its initial values and of the map it returns.
abstract final class ApplicationLabelFormFields {
  /// The label's text, by language code (`Map<String, String>`).
  static const String textId = 'text';

  /// The id of the input of the label's text in [code].
  static String textFieldId(String code) => 'text_$code';

  /// The language every label needs a text in.
  static const String english = 'en';
}
