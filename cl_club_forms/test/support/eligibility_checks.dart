import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

export 'package:cl_club_forms/src/widgets/gender_eligibility/gender_eligibility_field.dart'
    show GenderEligibilityField;

/// The checkbox of [gender] in the shared gender field.
Finder genderBox(EligibilityGender gender) => find.byKey(ValueKey(gender));

/// The Strict age checkbox of the shared age cluster.
Finder strictAgeBox() => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w is ShadCheckboxFormField &&
        w.id == AgeEligibilityFormFields.strictAgeId,
  ),
  matching: find.byType(ShadCheckbox),
);

/// Whether the box of [gender] is ticked.
bool genderTicked(WidgetTester tester, EligibilityGender gender) =>
    tester.widget<ShadCheckbox>(genderBox(gender)).value;

/// The genders whose boxes are ticked, in box order.
List<EligibilityGender> tickedGenders(WidgetTester tester) => [
  for (final gender in EligibilityGender.values)
    if (genderTicked(tester, gender)) gender,
];

/// Taps the box of each of [genders] and settles.
Future<void> tapGenders(
  WidgetTester tester,
  Iterable<EligibilityGender> genders,
) async {
  for (final gender in genders) {
    await tester.ensureVisible(genderBox(gender));
    await tester.tap(genderBox(gender));
    await tester.pumpAndSettle();
  }
}

/// The values entry of [genders], for a form's initial values.
Map<String, dynamic> gendersEntry(List<EligibilityGender> genders) => {
  GenderEligibilityFormFields.gendersId: genders,
};
