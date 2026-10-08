import 'package:cl_club_events/src/models/event_staff_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormFields, EventStaffMember;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show PickerUser;

const _organizer = PickerUser(username: 'org', displayName: 'Olivia Organizer');
const _coachA = PickerUser(username: 'coach_a', displayName: 'Aaron Coach');
const _coachB = PickerUser(username: 'coach_b', displayName: 'Bea Coach');

/// [member] as the pair the test compares.
(String, String) _pair(EventStaffMember member) =>
    (member.username, member.displayName);

void main() {
  group('Issue 104: buildEventStaffFormInitialValues', () {
    test('Issue 104: an organizer and coaches give the form its staff '
        'members, the coaches in order', () {
      final values = buildEventStaffFormInitialValues(
        organizer: _organizer,
        coaches: const [_coachA, _coachB],
      );

      expect(values.keys, [
        EventFormFields.organizerNameId,
        EventFormFields.coachNamesId,
      ]);
      expect(
        _pair(values[EventFormFields.organizerNameId] as EventStaffMember),
        ('org', 'Olivia Organizer'),
      );
      expect(
        (values[EventFormFields.coachNamesId] as List<EventStaffMember>).map(
          _pair,
        ),
        [('coach_a', 'Aaron Coach'), ('coach_b', 'Bea Coach')],
      );
    });

    test('Issue 104: nothing gives no organizer and no coach', () {
      final values = buildEventStaffFormInitialValues();

      expect(values.keys, [
        EventFormFields.organizerNameId,
        EventFormFields.coachNamesId,
      ]);
      expect(values[EventFormFields.organizerNameId], isNull);
      expect(
        values[EventFormFields.coachNamesId],
        isA<List<EventStaffMember>>().having((l) => l, 'coaches', isEmpty),
      );
    });
  });
}
