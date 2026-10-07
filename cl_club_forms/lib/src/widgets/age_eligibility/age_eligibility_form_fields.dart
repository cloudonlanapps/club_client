/// Field IDs of the shared age cluster (`AgeEligibilityFields`): one input
/// per part of the minimum and the maximum age, and the Strict age check.
///
/// The event and the group eligibility forms both embed the cluster, so both
/// carry these keys in their flat value map.
class AgeEligibilityFormFields {
  const AgeEligibilityFormFields._();

  static const String minAgeYearsId = 'minAgeYears';
  static const String minAgeMonthsId = 'minAgeMonths';
  static const String minAgeDaysId = 'minAgeDays';
  static const String maxAgeYearsId = 'maxAgeYears';
  static const String maxAgeMonthsId = 'maxAgeMonths';
  static const String maxAgeDaysId = 'maxAgeDays';
  static const String strictAgeId = 'strictAge';

  /// The three inputs of the minimum age: years, months, days.
  static const List<String> minAgeIds = [
    minAgeYearsId,
    minAgeMonthsId,
    minAgeDaysId,
  ];

  /// The three inputs of the maximum age: years, months, days.
  static const List<String> maxAgeIds = [
    maxAgeYearsId,
    maxAgeMonthsId,
    maxAgeDaysId,
  ];
}
