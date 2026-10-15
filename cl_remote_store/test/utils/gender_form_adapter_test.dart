import 'package:cl_club_forms/cl_club_forms.dart' show EligibilityGender;
import 'package:cl_remote_store/cl_remote_store.dart'
    show formGendersFromSdk, sdkGendersFromForm;
import 'package:club_sdk_2/club_sdk_2.dart' show Gender;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 80: gender form adapter', () {
    test('Issue 80: each SDK gender maps to its box, in box order', () {
      expect(
        formGendersFromSdk(const [
          Gender.preferNotToSay,
          Gender.male,
          Gender.other,
          Gender.female,
        ]),
        [
          EligibilityGender.boys,
          EligibilityGender.girls,
          EligibilityGender.other,
          EligibilityGender.preferNotToSay,
        ],
      );
    });

    test('Issue 80: ticked boxes map to SDK genders, in box order', () {
      expect(
        sdkGendersFromForm(const [
          EligibilityGender.preferNotToSay,
          EligibilityGender.boys,
          EligibilityGender.other,
        ]),
        [Gender.male, Gender.other, Gender.preferNotToSay],
      );
    });

    test('Issue 80: no gender maps to no box, and back', () {
      expect(formGendersFromSdk(const []), isEmpty);
      expect(sdkGendersFromForm(const []), isEmpty);
    });

    test('Issue 80: a round trip keeps every gender', () {
      for (final gender in Gender.values) {
        expect(sdkGendersFromForm(formGendersFromSdk([gender])), [gender]);
      }
    });
  });
}
