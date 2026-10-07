import 'package:cl_club_forms/cl_club_forms.dart' show FormAge;
import 'package:club_sdk_2/club_sdk_2.dart' show Age;

/// SDK [Age] → the forms' [FormAge] (`null` = no bound).
///
/// The one bridge between the two: the event and the group form adapters
/// and their read views all go through it.
FormAge? formAgeFromSdk(Age? age) => age == null
    ? null
    : FormAge(years: age.years, months: age.months, days: age.days);

/// The forms' [FormAge] → SDK [Age] (`null` = no bound).
Age? sdkAgeFromForm(FormAge? age) => age == null
    ? null
    : Age(years: age.years, months: age.months, days: age.days);
