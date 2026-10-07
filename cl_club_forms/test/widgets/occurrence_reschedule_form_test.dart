import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Map<String, dynamic> _seed() => {
  OccurrenceRescheduleFormFields.scheduleId: OneOffScheduleData(
    date: DateTime(2026, 7, 1),
    startTime: const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
    durationMinutes: 90,
  ),
  OccurrenceRescheduleFormFields.venueId: 7,
};

const _venues = [
  EventVenueOption(id: 7, name: 'Rink A'),
  EventVenueOption(id: 9, name: 'Rink B'),
];

void main() {
  testWidgets('Issue 750: renders the seeded venue and is not dirty at mount', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<OccurrenceRescheduleFormState>();
    await tester.pumpWidget(
      _wrap(
        OccurrenceRescheduleForm(
          key: key,
          initialValues: _seed(),
          venues: _venues,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rink A'), findsOneWidget);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets('Issue 750: validate returns the seeded schedule and venue', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<OccurrenceRescheduleFormState>();
    await tester.pumpWidget(
      _wrap(
        OccurrenceRescheduleForm(
          key: key,
          initialValues: _seed(),
          venues: _venues,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![OccurrenceRescheduleFormFields.venueId], 7);
    final schedule =
        values[OccurrenceRescheduleFormFields.scheduleId] as OneOffScheduleData;
    expect(schedule.durationMinutes, 90);
    expect(schedule.date, DateTime(2026, 7, 1));
  });
}
