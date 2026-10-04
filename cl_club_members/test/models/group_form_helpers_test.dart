import 'package:cl_club_members/src/models/group_form_helpers.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart'
    show GroupFormFields, GroupGender, GroupMode;

void main() {
  group('buildGroupFormInitialValues', () {
    test('null group → manual mode, empty fields', () {
      final values = buildGroupFormInitialValues(null);
      expect(values[GroupFormFields.modeId], GroupMode.manual);
      expect(values[GroupFormFields.nameId], '');
      expect(values[GroupFormFields.addMeId], false);
    });

    test('auto group populates fields and maps kind + gender', () {
      final after = DateTime.utc(2010);
      final before = DateTime.utc(2016, 12, 31);
      final group = Group(
        id: 1,
        name: 'U12 Boys',
        kind: GroupKind.auto,
        description: 'Under 12',
        dobOnOrAfterUtc: after,
        dobOnOrBeforeUtc: before,
        gender: Gender.male,
        createdAtUtc: DateTime.utc(2025),
      );

      final values = buildGroupFormInitialValues(group);

      expect(values[GroupFormFields.nameId], 'U12 Boys');
      expect(values[GroupFormFields.descriptionId], 'Under 12');
      expect(values[GroupFormFields.modeId], GroupMode.auto);
      expect(values[GroupFormFields.dobOnOrAfterId], after);
      expect(values[GroupFormFields.dobOnOrBeforeId], before);
      expect(values[GroupFormFields.genderId], GroupGender.male);
    });

    test('semi-auto group maps to GroupMode.semiAuto', () {
      final group = Group(
        id: 1,
        name: 'Semi',
        kind: GroupKind.semiAuto,
        dobOnOrAfterUtc: DateTime.utc(2010),
        createdAtUtc: DateTime.utc(2025),
      );

      final values = buildGroupFormInitialValues(group);
      expect(values[GroupFormFields.modeId], GroupMode.semiAuto);
    });

    test('manual group maps to GroupMode.manual with null criteria', () {
      final group = Group(
        id: 1,
        name: 'Manual Group',
        kind: GroupKind.manual,
        createdAtUtc: DateTime.utc(2025),
      );

      final values = buildGroupFormInitialValues(group);

      expect(values[GroupFormFields.modeId], GroupMode.manual);
      expect(values[GroupFormFields.descriptionId], '');
      expect(values[GroupFormFields.dobOnOrAfterId], isNull);
      expect(values[GroupFormFields.dobOnOrBeforeId], isNull);
      expect(values[GroupFormFields.genderId], isNull);
    });
  });
}
