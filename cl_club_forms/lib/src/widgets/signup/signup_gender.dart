/// Gender options of the user forms. Form-local, so the forms import no SDK
/// type; the host maps to and from the SDK enum.
enum SignupGender {
  male,
  female,
  other,
  preferNotToSay;

  /// Human-readable display label.
  String get label {
    return switch (this) {
      SignupGender.male => 'Male',
      SignupGender.female => 'Female',
      SignupGender.other => 'Other',
      SignupGender.preferNotToSay => 'Prefer not to say',
    };
  }
}
