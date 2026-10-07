import 'package:cl_club_forms/cl_club_forms.dart'
    show EventTimetableFormValidators, SessionInput;
import 'package:flutter_test/flutter_test.dart';

const List<SessionInput> _twoHours = [
  SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:00'),
];

void main() {
  const check = EventTimetableFormValidators.sessionsTotal;
  const refused = EventTimetableFormValidators.totalMismatchMessage;

  test('Issue 61: sessionsTotal accepts no split, whatever the length', () {
    expect(check(null, 120), isNull);
    expect(check(const [], 120), isNull);
    expect(check(const [], 0), isNull);
  });

  test('Issue 61: sessionsTotal accepts sessions that add up exactly', () {
    expect(check(_twoHours, 120), isNull);
    expect(
      check(
        const [SessionInput(name: 'All', startTime: '06:00', endTime: '07:00')],
        60,
      ),
      isNull,
    );
  });

  test('Issue 61: sessionsTotal refuses sessions one minute short or over', () {
    expect(check(_twoHours, 121), refused);
    expect(check(_twoHours, 119), refused);
  });

  test('Issue 61: sessionsTotal reads 12-hour session times too', () {
    const legacy = [
      SessionInput(name: 'A', startTime: '6:00 AM', endTime: '6:30 AM'),
      SessionInput(name: 'B', startTime: '6:30 AM', endTime: '8:00 AM'),
    ];
    expect(check(legacy, 120), isNull);
    expect(check(legacy, 90), refused);
  });

  test('Issue 61: sessionsTotal counts a session with an unreadable time as '
      'nothing, so the split is refused', () {
    const broken = [
      SessionInput(name: 'A', startTime: '06:00', endTime: '07:00'),
      SessionInput(name: 'B', startTime: 'soon', endTime: '08:00'),
    ];
    expect(check(broken, 120), refused);
  });
}
