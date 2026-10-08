/// One extra question an inquiry form asks beyond name, email, phone and
/// message.
///
/// The answers travel in the inquiry's `extra` map, which the server stores
/// as-is; [key] is what an admin reading the inquiry sees.
class InquiryChoice {
  const InquiryChoice({
    required this.key,
    required this.label,
    required this.placeholder,
    required this.options,
  });

  /// Names the question in the form's answers.
  final String key;

  /// The label of the question's row.
  final String label;

  /// Shown in the select until an option is picked.
  final String placeholder;

  /// Wire value to the label shown for it.
  final Map<String, String> options;
}
