// A programme's end is written only by terminate, extend and split, so the
// schedule a programme is created with has a start date and no end
// (club_client#121).
import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter_test/flutter_test.dart';

import '../support/programme_timetable_schedule_cluster.dart';

void main() {
  testWidgets('Issue 121: the programme schedule offers a start date and no '
      'end date', (tester) async {
    await pumpProgrammeField(tester, initialValue: validProgramme);

    expect(find.text('Start Date *'), findsOneWidget);
    expect(find.text('End Date'), findsNothing);
    expect(find.text('Ongoing'), findsNothing);
    expect(find.byType(CLDatePickerFormField), findsOneWidget);
  });
}
