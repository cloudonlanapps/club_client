import 'package:cl_club_members/src/widgets/add_to_group_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Issue #589 — Add to Group dialog must hide groups whose DOB/gender
/// criteria the target user fails. Server returns `notEligible` for these,
/// so listing them is a misleading affordance.
///
/// Issue #594 — The helper must mirror the server contract:
/// `services/group.py::add_members_bulk` only criteria-checks semi-auto
/// groups, and `is_eligible_for_semi_auto` exempts staff (admin/coach).
const memberRoles = UserRoles(
  isAdmin: false,
  isCoach: false,
  rawRoles: [],
);

const adminRoles = UserRoles(
  isAdmin: true,
  isCoach: false,
  rawRoles: [Role.admin],
);

const coachRoles = UserRoles(
  isAdmin: false,
  isCoach: true,
  rawRoles: [Role.coach],
);

void main() {
  group('Issue 589: userEligibleForGroup criteria checks (semi-auto)', () {
    Group buildSemiAutoGroup({
      DateTime? dobOnOrAfterUtc,
      DateTime? dobOnOrBeforeUtc,
      Gender? gender,
    }) => Group(
      id: 1,
      name: 'g',
      kind: GroupKind.semiAuto,
      dobOnOrAfterUtc: dobOnOrAfterUtc,
      dobOnOrBeforeUtc: dobOnOrBeforeUtc,
      gender: gender,
      createdAtUtc: DateTime.utc(2024),
    );

    test('Issue 589: semi-auto group without criteria accepts any user', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(),
          dateOfBirthUtc: null,
          gender: null,
          roles: memberRoles,
        ),
        isTrue,
      );
    });

    test('Issue 589: gender-constrained group excludes mismatched gender', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(gender: Gender.male),
          dateOfBirthUtc: DateTime.utc(2002),
          gender: Gender.female,
          roles: memberRoles,
        ),
        isFalse,
      );
    });

    test('Issue 589: gender-constrained group accepts matching gender', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(gender: Gender.male),
          dateOfBirthUtc: DateTime.utc(2002),
          gender: Gender.male,
          roles: memberRoles,
        ),
        isTrue,
      );
    });

    test(
      'Issue 589: gender-constrained group excludes user with no gender',
      () {
        expect(
          userEligibleForGroup(
            group: buildSemiAutoGroup(gender: Gender.male),
            dateOfBirthUtc: DateTime.utc(2002),
            gender: null,
            roles: memberRoles,
          ),
          isFalse,
        );
      },
    );

    test('Issue 589: DOB before dobOnOrAfterUtc lower bound is ineligible '
        '(user too old for the bracket)', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(dobOnOrAfterUtc: DateTime.utc(2008)),
          dateOfBirthUtc: DateTime.utc(2002),
          gender: Gender.male,
          roles: memberRoles,
        ),
        isFalse,
      );
    });

    test('Issue 589: DOB after dobOnOrBeforeUtc upper bound is ineligible '
        '(user too young for the bracket)', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(dobOnOrBeforeUtc: DateTime.utc(2007)),
          dateOfBirthUtc: DateTime.utc(2010),
          gender: Gender.male,
          roles: memberRoles,
        ),
        isFalse,
      );
    });

    test('Issue 589: DOB exactly on lower bound is eligible (inclusive)', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(dobOnOrAfterUtc: DateTime.utc(2008)),
          dateOfBirthUtc: DateTime.utc(2008),
          gender: null,
          roles: memberRoles,
        ),
        isTrue,
      );
    });

    test('Issue 589: DOB exactly on upper bound is eligible (inclusive)', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(dobOnOrBeforeUtc: DateTime.utc(2007)),
          dateOfBirthUtc: DateTime.utc(2007),
          gender: null,
          roles: memberRoles,
        ),
        isTrue,
      );
    });

    test('Issue 589: DOB-constrained group excludes user with no DOB', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(dobOnOrAfterUtc: DateTime.utc(2008)),
          dateOfBirthUtc: null,
          gender: Gender.male,
          roles: memberRoles,
        ),
        isFalse,
      );
    });

    test('Issue 589: DOB inside window with matching gender is eligible '
        '(Senior Men accepts a 2002-born male)', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(
            dobOnOrBeforeUtc: DateTime.utc(2007),
            gender: Gender.male,
          ),
          dateOfBirthUtc: DateTime.utc(2002),
          gender: Gender.male,
          roles: memberRoles,
        ),
        isTrue,
      );
    });

    test('Issue 589: DOB inside window but gender mismatch is ineligible '
        '(Senior Women rejects a male user born 2002)', () {
      expect(
        userEligibleForGroup(
          group: buildSemiAutoGroup(
            dobOnOrBeforeUtc: DateTime.utc(2007),
            gender: Gender.female,
          ),
          dateOfBirthUtc: DateTime.utc(2002),
          gender: Gender.male,
          roles: memberRoles,
        ),
        isFalse,
      );
    });
  });

  group('Issue 594: manual groups skip criteria (mirror server)', () {
    Group buildManualGroup({
      DateTime? dobOnOrAfterUtc,
      DateTime? dobOnOrBeforeUtc,
      Gender? gender,
    }) => Group(
      id: 2,
      name: 'g',
      kind: GroupKind.manual,
      dobOnOrAfterUtc: dobOnOrAfterUtc,
      dobOnOrBeforeUtc: dobOnOrBeforeUtc,
      gender: gender,
      createdAtUtc: DateTime.utc(2024),
    );

    test('Issue 594: manual group with criteria still accepts a user who '
        'would fail the same criteria on a semi-auto group', () {
      // Server's add_members_bulk only criteria-checks KIND_SEMI_AUTO.
      expect(
        userEligibleForGroup(
          group: buildManualGroup(
            dobOnOrBeforeUtc: DateTime.utc(2007),
            gender: Gender.female,
          ),
          dateOfBirthUtc: DateTime.utc(2002),
          gender: Gender.male,
          roles: memberRoles,
        ),
        isTrue,
      );
    });

    test('Issue 594: manual group with no criteria accepts a user with no '
        'DOB / gender', () {
      expect(
        userEligibleForGroup(
          group: buildManualGroup(),
          dateOfBirthUtc: null,
          gender: null,
          roles: memberRoles,
        ),
        isTrue,
      );
    });
  });

  group('Issue 594: staff bypass semi-auto criteria '
      '(server _user_is_staff exemption)', () {
    final seniorWomen = Group(
      id: 3,
      name: 'Senior Women',
      kind: GroupKind.semiAuto,
      dobOnOrBeforeUtc: DateTime.utc(2007),
      gender: Gender.female,
      createdAtUtc: DateTime.utc(2024),
    );

    test('Issue 594: admin user who fails DOB+gender is still eligible for '
        'a semi-auto group (server is_eligible_for_semi_auto returns true '
        'for staff)', () {
      expect(
        userEligibleForGroup(
          group: seniorWomen,
          dateOfBirthUtc: DateTime.utc(2010),
          gender: Gender.male,
          roles: adminRoles,
        ),
        isTrue,
      );
    });

    test('Issue 594: coach user who fails DOB+gender is still eligible for '
        'a semi-auto group', () {
      expect(
        userEligibleForGroup(
          group: seniorWomen,
          dateOfBirthUtc: DateTime.utc(2010),
          gender: Gender.male,
          roles: coachRoles,
        ),
        isTrue,
      );
    });

    test('Issue 594: plain member user who fails DOB+gender remains '
        'ineligible (regression guard for #589)', () {
      expect(
        userEligibleForGroup(
          group: seniorWomen,
          dateOfBirthUtc: DateTime.utc(2010),
          gender: Gender.male,
          roles: memberRoles,
        ),
        isFalse,
      );
    });
  });
}
