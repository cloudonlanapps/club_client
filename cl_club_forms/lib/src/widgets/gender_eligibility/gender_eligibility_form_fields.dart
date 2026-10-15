/// Field ID of the shared gender field (`GenderEligibilityField`).
///
/// The event and the group eligibility forms both embed the field, so both
/// carry this key in their flat value map.
class GenderEligibilityFormFields {
  const GenderEligibilityFormFields._();

  /// The ticked genders, a `List<EligibilityGender>`.
  static const String gendersId = 'genders';
}
