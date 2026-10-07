import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_validators.dart'
    show EventStaffFormValidators;
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_values.dart'
    show EventStaffFormValues;
import 'package:flutter_test/flutter_test.dart';

const _member = EventStaffMember(username: 'org', displayName: 'Olivia Org');

void main() {
  group('Issue 61: EventFormValidators.title', () {
    test('Issue 61: an empty title is required, by the name "Event name"', () {
      expect(EventFormValidators.title(''), 'Event name is required');
    });

    test('Issue 61: a title of blanks alone is required', () {
      expect(EventFormValidators.title('   '), 'Event name is required');
    });

    test('Issue 61: one character is too short', () {
      expect(EventFormValidators.title('A'), 'At least 2 characters');
    });

    test('Issue 61: blanks around one character do not make it two', () {
      expect(EventFormValidators.title('  A  '), 'At least 2 characters');
    });

    test('Issue 61: two characters and more are accepted', () {
      expect(EventFormValidators.title('U9'), isNull);
      expect(EventFormValidators.title(' U9 '), isNull);
      expect(EventFormValidators.title('Summer camp 2030'), isNull);
    });
  });

  group('Issue 61: EventStaffFormValidators.organizer', () {
    test('Issue 61: no organizer is refused', () {
      expect(
        EventStaffFormValidators.organizer(null),
        EventStaffFormValidators.organizerRequired,
      );
      expect(
        EventStaffFormValidators.organizerRequired,
        'An organizer is required',
      );
    });

    test('Issue 61: an organizer is accepted', () {
      expect(EventStaffFormValidators.organizer(_member), isNull);
    });
  });

  group('Issue 61: EventStaffFormValues', () {
    test("Issue 61: organizerUsername is the picked member's username, null "
        'without one', () {
      expect(
        EventStaffFormValues.organizerUsername(const {
          EventFormFields.organizerNameId: _member,
        }),
        'org',
      );
      expect(
        EventStaffFormValues.organizerUsername(const {
          EventFormFields.organizerNameId: null,
        }),
        isNull,
      );
      expect(EventStaffFormValues.organizerUsername(const {}), isNull);
    });

    test('Issue 61: coachUsernames are the usernames in the order held, '
        'empty without the entry', () {
      expect(
        EventStaffFormValues.coachUsernames(const {
          EventFormFields.coachNamesId: [
            EventStaffMember(username: 'b', displayName: 'B'),
            _member,
            EventStaffMember(username: 'a', displayName: 'A'),
          ],
        }),
        ['b', 'org', 'a'],
      );
      expect(EventStaffFormValues.coachUsernames(const {}), isEmpty);
      expect(
        EventStaffFormValues.coachUsernames(const {
          EventFormFields.coachNamesId: null,
        }),
        isEmpty,
      );
    });
  });

  group('Issue 61: EventStaffMember', () {
    String initials(String name) =>
        EventStaffMember(username: 'u', displayName: name).initials;

    test('Issue 61: initials are the first letters of the first and the '
        'last word, in capitals', () {
      expect(initials('Olivia Organizer'), 'OO');
      expect(initials('aaron de coach'), 'AC');
    });

    test('Issue 61: a single word gives one initial', () {
      expect(initials('aaron'), 'A');
    });

    test('Issue 61: blanks around and between the words are ignored', () {
      expect(initials('  Bea   Coach  '), 'BC');
    });

    test('Issue 61: an empty name gives a question mark', () {
      expect(initials(''), '?');
      expect(initials('   '), '?');
    });

    test('Issue 61: members are equal by username and name', () {
      // Built at run time, so it is not the same object as the constant.
      final a = EventStaffMember(
        username: ['o', 'r', 'g'].join(),
        displayName: ['Olivia', 'Org'].join(' '),
      );
      expect(a, _member);
      expect(a.hashCode, _member.hashCode);
      expect(
        a,
        isNot(const EventStaffMember(username: 'org', displayName: 'Other')),
      );
      expect(
        a,
        isNot(const EventStaffMember(username: 'x', displayName: 'Olivia Org')),
      );
      expect(
        a.toString(),
        'EventStaffMember(username: org, displayName: Olivia Org)',
      );
    });
  });

  group('Issue 61: EventGender', () {
    test('Issue 61: every gender has the label the select shows', () {
      expect(
        {for (final g in EventGender.values) g: g.label},
        {
          EventGender.male: 'Male',
          EventGender.female: 'Female',
          EventGender.other: 'Other',
          EventGender.preferNotToSay: 'Prefer not to say',
        },
      );
    });
  });
}
