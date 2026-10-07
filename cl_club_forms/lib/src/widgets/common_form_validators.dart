/// Shared, SDK-free field validators reused across entity forms (group,
/// venue, and — in future — events) so a common concept like "name" validates
/// identically everywhere instead of each form re-implementing the rule.
class CommonFormValidators {
  const CommonFormValidators._();

  /// An entity display name: required and at least 2 characters. [label]
  /// prefixes the "required" message so each entity reads naturally
  /// (`'Group name'`, `'Venue name'`, `'Event name'`, …) while the rule stays
  /// identical.
  static String? name(String value, {required String label}) {
    final t = value.trim();
    if (t.isEmpty) return '$label is required';
    if (t.length < 2) return 'At least 2 characters';
    return null;
  }
}
