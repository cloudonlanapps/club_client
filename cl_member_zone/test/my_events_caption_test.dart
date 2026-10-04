import 'package:cl_member_zone/src/widgets/panels/my_events/my_events_caption.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('myEventsFutureCaption', () {
    test('Leave requested takes precedence over enrollment', () {
      expect(
        myEventsFutureCaption(
          AttendanceStatus.onLeaveRequested,
          EnrollmentStatus.assigned,
        ),
        'Leave requested',
      );
    });

    test('Leave approved takes precedence over enrollment', () {
      expect(
        myEventsFutureCaption(
          AttendanceStatus.onLeave,
          EnrollmentStatus.accepted,
        ),
        'Leave approved',
      );
    });

    test('falls back to enrollment caption when no leave state', () {
      expect(
        myEventsFutureCaption(null, EnrollmentStatus.assigned),
        'You are assigned',
      );
      expect(
        myEventsFutureCaption(null, EnrollmentStatus.accepted),
        'You are accepted',
      );
    });
  });

  group('myEventsPastCaption', () {
    test('uses attendance status when present', () {
      expect(myEventsPastCaption(AttendanceStatus.present), 'You attended');
      expect(myEventsPastCaption(AttendanceStatus.absent), 'You were absent');
      expect(myEventsPastCaption(AttendanceStatus.late), 'You were late');
      expect(
        myEventsPastCaption(AttendanceStatus.onLeave),
        'You were on leave',
      );
    });

    test('falls back to "Attendance not recorded" when no record', () {
      expect(myEventsPastCaption(null), 'Attendance not recorded');
    });
  });
}
