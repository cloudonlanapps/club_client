// Issue 320, MembershipDateForm: the day a member joined the club, which an
// admin corrects in the account section of the profile. A date-only value.
import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_harness.dart';

const String _id = UserFormFields.membershipDateUtcId;

Future<MembershipDateFormState> _pump(
  WidgetTester tester, {
  DateTime? initialValue,
  bool enabled = true,
}) async {
  final key = GlobalKey<MembershipDateFormState>();
  await pumpForm(
    tester,
    MembershipDateForm(key: key, initialValue: initialValue, enabled: enabled),
  );
  return key.currentState!;
}

Future<void> _pick(WidgetTester tester, DateTime? day) async {
  tester
      .state<FormFieldState<DateTime?>>(find.byType(CLDatePickerFormField))
      .didChange(day);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 320: MembershipDateForm', () {
    testWidgets('Issue 320: it shows one labelled date field and no chrome', (
      tester,
    ) async {
      await _pump(tester, initialValue: DateTime.utc(2025, 4, 2));

      expect(rowLabels(tester), ['Membership date *']);
      expect(find.byType(CLDatePickerFormField), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 320: the seeded date comes back unchanged and the '
        'form is not dirty', (tester) async {
      final state = await _pump(tester, initialValue: DateTime.utc(2025, 4, 2));

      expect(state.isDirty, isFalse);
      expect(state.validate(), {_id: DateTime.utc(2025, 4, 2)});
    });

    testWidgets('Issue 320: a picked day comes back as that day at UTC '
        'midnight', (tester) async {
      final state = await _pump(tester, initialValue: DateTime.utc(2025, 4, 2));

      await _pick(tester, DateTime(2025, 5, 9));

      expect(state.isDirty, isTrue);
      expect(state.validate(), {_id: DateTime.utc(2025, 5, 9)});
    });

    testWidgets('Issue 320: a blank date is refused on the field', (
      tester,
    ) async {
      final state = await _pump(tester);

      expect(state.validate(), isNull);
      await tester.pump();
      expect(find.text('Pick the membership date'), findsOneWidget);
    });

    testWidgets("Issue 320: it shows the server's refusal on the field", (
      tester,
    ) async {
      final state = await _pump(tester, initialValue: DateTime.utc(2025, 4, 2));

      state.showErrors(fieldErrors: {_id: 'Not a UTC midnight'});
      await tester.pump();

      expect(find.text('Not a UTC midnight'), findsOneWidget);
    });
  });
}
