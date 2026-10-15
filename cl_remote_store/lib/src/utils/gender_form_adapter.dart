import 'package:cl_club_forms/cl_club_forms.dart' show EligibilityGender;
import 'package:club_sdk_2/club_sdk_2.dart' show Gender;

/// SDK [Gender]s of an event's or a group's criterion → the forms'
/// [EligibilityGender]s, in the order the boxes show (empty = no criterion).
///
/// The one bridge between the two: the event and the group form adapters
/// and their read views all go through it.
List<EligibilityGender> formGendersFromSdk(Iterable<Gender> genders) {
  final held = genders.toSet();
  return [
    for (final gender in EligibilityGender.values)
      if (held.contains(sdkGenderFromForm(gender))) gender,
  ];
}

/// The forms' [EligibilityGender]s → SDK [Gender]s, in the order the boxes
/// show (empty = no criterion).
List<Gender> sdkGendersFromForm(Iterable<EligibilityGender> genders) {
  final held = genders.toSet();
  return [
    for (final gender in EligibilityGender.values)
      if (held.contains(gender)) sdkGenderFromForm(gender),
  ];
}

/// The SDK [Gender] a box stands for.
Gender sdkGenderFromForm(EligibilityGender gender) => switch (gender) {
  EligibilityGender.boys => Gender.male,
  EligibilityGender.girls => Gender.female,
  EligibilityGender.other => Gender.other,
  EligibilityGender.preferNotToSay => Gender.preferNotToSay,
};
