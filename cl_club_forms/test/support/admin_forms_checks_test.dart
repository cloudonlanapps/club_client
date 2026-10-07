import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_forms_checks.dart';
import 'form_harness.dart';

void main() {
  group('Issue 61: the checks of admin_forms_checks, on VenueCreateForm', () {
    Future<VenueCreateFormState> pump(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      final key = GlobalKey<VenueCreateFormState>();
      await pumpForm(tester, VenueCreateForm(key: key, enabled: enabled));
      return key.currentState!;
    }

    testWidgets('Issue 61: expectNoFieldResponds passes on a form that is '
        'off', (tester) async {
      await pump(tester, enabled: false);
      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: expectNoFieldResponds fails on a form that is '
        'on', (tester) async {
      await pump(tester);
      await expectLater(
        () => expectNoFieldResponds(tester),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('Issue 61: a tap on a live input opens the keyboard and one '
        'on a live switch changes the value, which is what the check '
        'watches for', (tester) async {
      final state = await pump(tester);

      await tester.tap(fieldWithId(VenueFormFields.nameId));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.hasAnyClients, isTrue);

      await tester.tap(fieldWithId(VenueFormFields.isFeaturedId));
      await tester.pumpAndSettle();
      expect(formOf(tester).value[VenueFormFields.isFeaturedId], isTrue);
      expect(state.isDirty, isTrue);
    });

    testWidgets('Issue 61: expectFieldError wants the message on the named '
        'field', (tester) async {
      final state = await pump(tester);
      state.showErrors(fieldErrors: {VenueFormFields.nameId: 'Taken.'});
      await tester.pumpAndSettle();

      expectFieldError(VenueFormFields.nameId, 'Taken.');
      expect(
        () => expectFieldError(VenueFormFields.addressId, 'Taken.'),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('Issue 61: expectSavesAfterRefusal returns what the form '
        'then saves', (tester) async {
      final state = await pump(tester);
      await enterField(tester, VenueFormFields.nameId, 'Main Arena');

      final values = await expectSavesAfterRefusal(
        tester,
        state,
        VenueFormFields.nameId,
      );
      expect(values[VenueFormFields.nameId], 'Main Arena');
    });
  });
}
