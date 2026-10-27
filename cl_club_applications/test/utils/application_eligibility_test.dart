import 'package:cl_club_applications/src/utils/application_eligibility.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';

UserPrivate _member({DateTime? born, Gender? gender}) => UserPrivate(
  username: 'member_a',
  displayName: 'Member A',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  dateOfBirthUtc: born,
  gender: gender,
);

ApplicationTemplate _template(List<ApplicationAgeCategory> categories) =>
    ApplicationSamples.template(
      status: ApplicationStatus.published,
      content: ApplicationSamples.content.copyWith(
        ageCategories: categories,
      ),
    );

final _junior = ApplicationAgeCategory(
  label: const {'en': 'Junior'},
  bornOnOrAfterUtc: DateTime.utc(2014),
  bornOnOrBeforeUtc: DateTime.utc(2016, 12, 31),
);

void main() {
  group('Issue 380: who an application is for', () {
    test('Issue 380: a template without age categories is for everyone', () {
      expect(isEligibleFor(_template(const []), _member()), isTrue);
    });

    test('Issue 380: both bounds are inclusive days', () {
      bool born(DateTime day) => fitsAgeCategory(_junior, day, Gender.female);
      expect(born(DateTime.utc(2014)), isTrue, reason: 'first day');
      expect(born(DateTime.utc(2016, 12, 31)), isTrue, reason: 'last day');
      expect(born(DateTime.utc(2013, 12, 31)), isFalse, reason: 'too old');
      expect(born(DateTime.utc(2017)), isFalse, reason: 'too young');
    });

    test('Issue 380: a missing bound is open', () {
      final open = ApplicationAgeCategory(
        label: const {'en': 'Open'},
        bornOnOrBeforeUtc: DateTime.utc(2000),
      );
      expect(fitsAgeCategory(open, DateTime.utc(1950), null), isTrue);
      expect(fitsAgeCategory(open, DateTime.utc(2001), null), isFalse);
    });

    test('Issue 380: listed genders admit only those; none listed admits '
        'any', () {
      const girls = ApplicationAgeCategory(
        label: {'en': 'Girls'},
        genders: [Gender.female],
      );
      final day = DateTime.utc(2015);
      expect(fitsAgeCategory(girls, day, Gender.female), isTrue);
      expect(fitsAgeCategory(girls, day, Gender.male), isFalse);
      expect(fitsAgeCategory(girls, day, null), isFalse);
      expect(fitsAgeCategory(_junior, day, null), isTrue);
    });

    test('Issue 380: no date of birth fits no category', () {
      const any = ApplicationAgeCategory(label: {'en': 'Any'});
      expect(fitsAgeCategory(any, null, Gender.male), isFalse);
      expect(isEligibleFor(_template([any]), _member()), isFalse);
    });

    test('Issue 380: fitting one category of several is enough', () {
      final template = _template([
        _junior,
        ApplicationAgeCategory(
          label: const {'en': 'Adult'},
          bornOnOrBeforeUtc: DateTime.utc(2007, 12, 31),
        ),
      ]);
      expect(isEligibleFor(template, _member(born: DateTime.utc(1990))), true);
      expect(isEligibleFor(template, _member(born: DateTime.utc(2010))), false);
    });

    test('Issue 380: a missing date of birth hides only templates with '
        'categories', () {
      expect(
        hiddenForMissingDateOfBirth([_template(const [])], _member()),
        isFalse,
      );
      expect(
        hiddenForMissingDateOfBirth([
          _template([_junior]),
        ], _member()),
        isTrue,
      );
      expect(
        hiddenForMissingDateOfBirth(
          [
            _template([_junior]),
          ],
          _member(born: DateTime.utc(1990)),
        ),
        isFalse,
      );
    });
  });
}
