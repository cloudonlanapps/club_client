import 'package:cl_remote_store/src/utils/event_eligibility.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event({
  List<Gender> genders = const [],
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
}) {
  final now = DateTime.utc(2026);
  return Event(
    id: 1,
    title: 'E',
    description: '',
    type: EventType.camp,
    visibility: Visibility.private,
    venueId: 1,
    startTimeUtc: now,
    endTimeUtc: now.add(const Duration(hours: 2)),
    createdAtUtc: now,
    updatedAtUtc: now,
    genders: genders,
    dobOnOrAfterUtc: dobOnOrAfterUtc,
    dobOnOrBeforeUtc: dobOnOrBeforeUtc,
  );
}

UserPrivate _user({Gender? gender, DateTime? dateOfBirthUtc}) {
  return UserPrivate(
    username: 'u',
    displayName: 'U',
    firstName: 'U',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2020),
    gender: gender,
    dateOfBirthUtc: dateOfBirthUtc,
  );
}

void main() {
  group('checkEventEligibility', () {
    test('no criteria → eligible regardless of profile', () {
      expect(
        checkEventEligibility(event: _event(), user: _user()),
        isNull,
      );
    });

    test('gender constraint + matching gender → eligible', () {
      expect(
        checkEventEligibility(
          event: _event(genders: const [Gender.female]),
          user: _user(gender: Gender.female),
        ),
        isNull,
      );
    });

    test('gender constraint + missing gender → genderMissing', () {
      final f = checkEventEligibility(
        event: _event(genders: const [Gender.female]),
        user: _user(),
      );
      expect(f, isNotNull);
      expect(f!.reason, EligibilityFailureReason.genderMissing);
    });

    test('gender constraint + wrong gender → genderMismatch', () {
      final f = checkEventEligibility(
        event: _event(genders: const [Gender.female]),
        user: _user(gender: Gender.male),
      );
      expect(f, isNotNull);
      expect(f!.reason, EligibilityFailureReason.genderMismatch);
    });

    test('dob window + missing DOB → dobMissing', () {
      final f = checkEventEligibility(
        event: _event(dobOnOrAfterUtc: DateTime.utc(2010)),
        user: _user(),
      );
      expect(f, isNotNull);
      expect(f!.reason, EligibilityFailureReason.dobMissing);
    });

    test('dob too old (before lower bound) → dobOutOfWindow', () {
      final f = checkEventEligibility(
        event: _event(dobOnOrAfterUtc: DateTime.utc(2010)),
        user: _user(dateOfBirthUtc: DateTime.utc(2005)),
      );
      expect(f, isNotNull);
      expect(f!.reason, EligibilityFailureReason.dobOutOfWindow);
    });

    test('dob too young (after upper bound) → dobOutOfWindow', () {
      final f = checkEventEligibility(
        event: _event(dobOnOrBeforeUtc: DateTime.utc(2015)),
        user: _user(dateOfBirthUtc: DateTime.utc(2020)),
      );
      expect(f, isNotNull);
      expect(f!.reason, EligibilityFailureReason.dobOutOfWindow);
    });

    test('dob inside the window → eligible', () {
      expect(
        checkEventEligibility(
          event: _event(
            dobOnOrAfterUtc: DateTime.utc(2010),
            dobOnOrBeforeUtc: DateTime.utc(2015),
          ),
          user: _user(dateOfBirthUtc: DateTime.utc(2012)),
        ),
        isNull,
      );
    });

    test('combined criteria all met → eligible', () {
      expect(
        checkEventEligibility(
          event: _event(
            genders: const [Gender.female],
            dobOnOrAfterUtc: DateTime.utc(2010),
            dobOnOrBeforeUtc: DateTime.utc(2015),
          ),
          user: _user(
            gender: Gender.female,
            dateOfBirthUtc: DateTime.utc(2012),
          ),
        ),
        isNull,
      );
    });

    test('Issue 80: a user whose gender is in the list is eligible', () {
      expect(
        checkEventEligibility(
          event: _event(
            genders: const [Gender.male, Gender.other, Gender.preferNotToSay],
          ),
          user: _user(gender: Gender.other),
        ),
        isNull,
      );
    });

    test('Issue 80: a user whose gender is not in the list → '
        'genderMismatch', () {
      final f = checkEventEligibility(
        event: _event(genders: const [Gender.male, Gender.other]),
        user: _user(gender: Gender.female),
      );
      expect(f?.reason, EligibilityFailureReason.genderMismatch);
      expect(f?.message, "This event is not open to the user's gender.");
    });

    test('Issue 80: a list of genders + missing gender → genderMissing', () {
      final f = checkEventEligibility(
        event: _event(genders: const [Gender.male, Gender.female]),
        user: _user(),
      );
      expect(f?.reason, EligibilityFailureReason.genderMissing);
    });
  });
}
