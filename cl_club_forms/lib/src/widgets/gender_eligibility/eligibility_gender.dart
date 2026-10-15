/// A gender an event or a group may be open to: one per gender a person can
/// register with. The eligibility forms hold a list of these; the caller's
/// adapter maps them to and from the SDK `Gender`.
enum EligibilityGender {
  /// Members who registered as male.
  boys,

  /// Members who registered as female.
  girls,

  /// Members who registered as other.
  other,

  /// Members who registered as prefer not to say.
  preferNotToSay;

  /// The checkbox's text, and the name the read views use.
  String get label => switch (this) {
    EligibilityGender.boys => 'Boys',
    EligibilityGender.girls => 'Girls',
    EligibilityGender.other => 'Other',
    EligibilityGender.preferNotToSay => 'Prefer not to say',
  };
}
