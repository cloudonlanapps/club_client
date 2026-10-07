import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'form_harness.dart';

void main() {
  group('Issue 61: the form test harness, on EventCancellationForm', () {
    Future<EventCancellationFormState> pump(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      final key = GlobalKey<EventCancellationFormState>();
      await pumpForm(
        tester,
        EventCancellationForm(
          key: key,
          enabled: enabled,
          sessions: [
            EventCancellationSession(
              start: DateTime(2026, 11, 14, 18),
              label: 'Sat 14 Nov, 18:00',
            ),
          ],
        ),
      );
      return key.currentState!;
    }

    testWidgets('Issue 61: it reads the rows and their required marks', (
      tester,
    ) async {
      await pump(tester);
      expect(rowLabels(tester), ['Cancel from *', 'Reason *']);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: it types into a field and reads the values back', (
      tester,
    ) async {
      final state = await pump(tester);
      expect(state.isDirty, isFalse);
      await enterField(
        tester,
        EventCancellationFormFields.reasonId,
        ' Rink closed ',
      );
      expect(state.isDirty, isTrue);
      expect(
        state.validate()![EventCancellationFormFields.reasonId],
        'Rink closed',
      );
    });

    testWidgets('Issue 61: it checks showErrors on a field and inline', (
      tester,
    ) async {
      final state = await pump(tester);
      await expectShowsServerErrors(
        tester,
        state,
        EventCancellationFormFields.reasonId,
      );
    });

    testWidgets('Issue 61: it checks a form at phone width', (tester) async {
      await expectFitsPhone(tester, const EventCancellationForm());
    });
  });
}
