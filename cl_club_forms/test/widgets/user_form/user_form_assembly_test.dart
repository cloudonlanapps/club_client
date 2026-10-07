import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserFormAssembly.floorToUtcMidnight', () {
    test('Issue 230: null in → null out', () {
      expect(UserFormAssembly.floorToUtcMidnight(null), isNull);
    });

    test(
      'Issue 230: local DateTime is floored to UTC midnight of the same '
      'calendar date',
      () {
        // The DOB picker emits a local DateTime; storing that as an instant
        // shifts the calendar date by up to one day in any non-UTC TZ. The
        // floor utility must collapse it to UTC midnight of the picked date
        // regardless of the host's timezone.
        // Spelling out month/day keeps the boundary-date intent obvious even
        // though they match Dart's defaults.
        final picked = DateTime(2014, 1, 1);
        final floored = UserFormAssembly.floorToUtcMidnight(picked);

        expect(floored, isNotNull);
        expect(floored!.isUtc, isTrue);
        expect(floored.year, 2014);
        expect(floored.month, 1);
        expect(floored.day, 1);
        expect(floored.hour, 0);
        expect(floored.minute, 0);
        expect(floored.second, 0);
        expect(floored.millisecond, 0);
      },
    );

    test('Issue 230: already-UTC midnight DateTime round-trips unchanged', () {
      final utcMidnight = DateTime.utc(2017, 12, 31);
      final floored = UserFormAssembly.floorToUtcMidnight(utcMidnight);
      expect(floored, equals(utcMidnight));
    });

    test('Issue 230: non-midnight UTC DateTime is floored to UTC midnight', () {
      // Simulates the broken pipeline before the fix: a DOB stored as an
      // east-of-UTC instant (e.g. 2013-12-31 18:30 UTC for IST 1-Jan-2014).
      // Re-flooring it shouldn't shift the calendar day in the picker's TZ —
      // it should yield the UTC-day component of the input.
      final instant = DateTime.utc(2014, 6, 15, 5, 30);
      final floored = UserFormAssembly.floorToUtcMidnight(instant);
      expect(floored, equals(DateTime.utc(2014, 6, 15)));
    });
  });

  group('Issue 61: UserFormAssembly.mergeEmergencyContact', () {
    test('Issue 61: nothing given merges to null', () {
      expect(UserFormAssembly.mergeEmergencyContact(), isNull);
      expect(
        UserFormAssembly.mergeEmergencyContact(
          name: ' ',
          relation: '',
          phone: '  ',
        ),
        isNull,
      );
    });

    test('Issue 61: name, relation and phone merge to '
        '"Name (Relation) : Phone", each trimmed', () {
      expect(
        UserFormAssembly.mergeEmergencyContact(
          name: ' Meera Rao ',
          relation: ' Parent ',
          phone: ' 9876543210 ',
        ),
        'Meera Rao (Parent) : 9876543210',
      );
    });

    test('Issue 61: each part alone, and each pair, merges without the '
        'missing part', () {
      String? merge({String? name, String? relation, String? phone}) =>
          UserFormAssembly.mergeEmergencyContact(
            name: name,
            relation: relation,
            phone: phone,
          );
      expect(merge(name: 'Meera'), 'Meera');
      expect(merge(relation: 'Parent'), '(Parent)');
      expect(merge(phone: '9876543210'), '9876543210');
      expect(merge(name: 'Meera', relation: 'Parent'), 'Meera (Parent)');
      expect(merge(name: 'Meera', phone: '9876543210'), 'Meera : 9876543210');
      expect(
        merge(relation: 'Parent', phone: '9876543210'),
        '(Parent) : 9876543210',
      );
    });
  });

  group('Issue 61: UserFormAssembly.parseEmergencyContact', () {
    test('Issue 61: null, empty and blank parse to nothing', () {
      for (final empty in [null, '', '   ']) {
        expect(UserFormAssembly.parseEmergencyContact(empty), (
          name: null,
          relation: null,
          phone: null,
        ));
      }
    });

    test('Issue 61: the full form parses back into its three parts', () {
      expect(
        UserFormAssembly.parseEmergencyContact(
          'Meera Rao (Parent) : 9876543210',
        ),
        (name: 'Meera Rao', relation: 'Parent', phone: '9876543210'),
      );
    });

    test('Issue 61: a value without " : " is a name with no phone', () {
      expect(UserFormAssembly.parseEmergencyContact('Meera (Sibling)'), (
        name: 'Meera',
        relation: 'Sibling',
        phone: null,
      ));
      expect(UserFormAssembly.parseEmergencyContact('Meera'), (
        name: 'Meera',
        relation: null,
        phone: null,
      ));
    });

    test('Issue 61: a relation or a phone alone parses to that part', () {
      expect(UserFormAssembly.parseEmergencyContact('(Friend)'), (
        name: null,
        relation: 'Friend',
        phone: null,
      ));
      expect(UserFormAssembly.parseEmergencyContact(' : 9876543210'), (
        name: null,
        relation: null,
        phone: '9876543210',
      ));
    });

    test('Issue 61: a relation that is not one of the options is dropped, '
        'and taken out of the name', () {
      expect(
        UserFormAssembly.parseEmergencyContact('Meera (Aunt) : 9876543210'),
        (name: 'Meera', relation: null, phone: '9876543210'),
      );
    });

    test('Issue 61: every relation option survives merge then parse', () {
      expect(UserFormAssembly.emergencyRelations, [
        'Parent',
        'Spouse',
        'Sibling',
        'Child',
        'Friend',
        'Other',
      ]);
      for (final relation in UserFormAssembly.emergencyRelations) {
        final merged = UserFormAssembly.mergeEmergencyContact(
          name: 'Meera Rao',
          relation: relation,
          phone: '+91 9876543210',
        );
        expect(UserFormAssembly.parseEmergencyContact(merged), (
          name: 'Meera Rao',
          relation: relation,
          phone: '+91 9876543210',
        ), reason: relation);
      }
    });
  });

  group('Issue 61: UserFormAssembly.assembleAddress and FormAddress', () {
    test('Issue 61: no field, or only blank ones, assembles to null', () {
      expect(UserFormAssembly.assembleAddress(), isNull);
      expect(
        UserFormAssembly.assembleAddress(
          addrLine1: '',
          addrLine2: ' ',
          city: '',
          state: '',
          pincode: '  ',
        ),
        isNull,
      );
    });

    test('Issue 61: any one field makes an address, the others kept as '
        'given', () {
      final byCity = UserFormAssembly.assembleAddress(city: 'Pune');
      expect(byCity, isNotNull);
      expect(byCity!.city, 'Pune');
      expect(byCity.addrLine1, isNull);

      final full = UserFormAssembly.assembleAddress(
        addrLine1: '12 MG Road',
        addrLine2: 'Camp',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
      )!;
      expect(
        [full.addrLine1, full.addrLine2, full.city, full.state, full.pincode],
        ['12 MG Road', 'Camp', 'Pune', 'Maharashtra', '411001'],
      );
    });

    test('Issue 61: FormAddress.isEmpty is false as soon as one field has '
        'text', () {
      expect(const FormAddress().isEmpty, isTrue);
      expect(const FormAddress(addrLine1: ' ', pincode: '').isEmpty, isTrue);
      expect(const FormAddress(addrLine1: 'x').isEmpty, isFalse);
      expect(const FormAddress(addrLine2: 'x').isEmpty, isFalse);
      expect(const FormAddress(city: 'x').isEmpty, isFalse);
      expect(const FormAddress(state: 'x').isEmpty, isFalse);
      expect(const FormAddress(pincode: 'x').isEmpty, isFalse);
    });
  });

  group('Issue 61: UserFormAssembly.seed, pick and maybe', () {
    test('Issue 61: seed without a source gives every id its empty value: '
        "'' for a text, and what emptyValues says otherwise", () {
      final seeded = UserFormAssembly.seed(UserFormFields.userIds, null);

      expect(seeded.keys, UserFormFields.userIds);
      for (final id in UserFormFields.userIds) {
        expect(
          seeded[id],
          UserFormFields.emptyValues.containsKey(id)
              ? UserFormFields.emptyValues[id]
              : '',
          reason: id,
        );
      }
      expect(seeded[UserFormFields.useDefaultPasswordId], isTrue);
      expect(seeded[UserFormFields.genderId], isNull);
      expect(seeded[UserFormFields.firstNameId], '');
    });

    test('Issue 61: seed takes what the source holds, ignores ids it was '
        'not asked for, and fills a null from the empty value', () {
      final seeded = UserFormAssembly.seed(UserFormFields.addressIds, const {
        UserFormFields.cityId: 'Pune',
        UserFormFields.stateId: 'Maharashtra',
        UserFormFields.addrLine1Id: null,
        UserFormFields.emailId: 'robin@example.test',
      });

      expect(seeded, {
        UserFormFields.addrLine1Id: '',
        UserFormFields.addrLine2Id: '',
        UserFormFields.cityId: 'Pune',
        UserFormFields.stateId: 'Maharashtra',
        UserFormFields.pincodeId: '',
      });
    });

    test('Issue 61: seed keeps a false and a set flag from the source', () {
      final seeded = UserFormAssembly.seed(
        const [
          UserFormFields.useDefaultPasswordId,
          UserFormFields.useNamePubliclyId,
        ],
        const {
          UserFormFields.useDefaultPasswordId: false,
          UserFormFields.useNamePubliclyId: true,
        },
      );

      expect(seeded, {
        UserFormFields.useDefaultPasswordId: false,
        UserFormFields.useNamePubliclyId: true,
      });
    });

    test('Issue 61: pick gives exactly the ids asked for, a missing one as '
        'null', () {
      expect(
        UserFormAssembly.pick(
          const [UserFormFields.cityId, UserFormFields.stateId],
          const {
            UserFormFields.cityId: ' Pune ',
            UserFormFields.emailId: 'robin@example.test',
          },
        ),
        {UserFormFields.cityId: ' Pune ', UserFormFields.stateId: null},
      );
    });

    test('Issue 61: maybe trims a text and turns an empty, blank or '
        'missing one into null', () {
      const values = <String, dynamic>{
        'a': ' Robin ',
        'b': '',
        'c': '   ',
        'd': null,
      };
      expect(UserFormAssembly.maybe('a', values), 'Robin');
      expect(UserFormAssembly.maybe('b', values), isNull);
      expect(UserFormAssembly.maybe('c', values), isNull);
      expect(UserFormAssembly.maybe('d', values), isNull);
      expect(UserFormAssembly.maybe('missing', values), isNull);
    });
  });
}
