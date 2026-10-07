/// Static validators for `RenameForm`.
class RenameFormValidators {
  const RenameFormValidators._();

  /// The form's default rule: [value] is not blank. The message names the
  /// field by its [label].
  static String? required(String value, {required String label}) =>
      value.trim().isEmpty ? '$label is required' : null;
}
