import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('Issue 678: no-constraint form validates and stays clean', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    // The section editor always seeds the three eligibility keys (null when
    // unset), mirroring buildEventFormInitialValues for an open event.
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: const {
            EventFormFields.genderId: null,
            EventFormFields.dobOnOrAfterId: null,
            EventFormFields.dobOnOrBeforeId: null,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![EventFormFields.genderId], isNull);
    expect(values[EventFormFields.dobOnOrAfterId], isNull);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets('Issue 678: seeded values validate and start clean', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: {
            EventFormFields.genderId: EventGender.male,
            EventFormFields.dobOnOrAfterId: DateTime.utc(2010),
            EventFormFields.dobOnOrBeforeId: DateTime.utc(2014),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![EventFormFields.genderId], EventGender.male);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets('Issue 678: rejects an inverted DOB window', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<EventEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        EventEligibilityForm(
          key: key,
          initialValues: {
            EventFormFields.dobOnOrAfterId: DateTime.utc(2014),
            EventFormFields.dobOnOrBeforeId: DateTime.utc(2010),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.textContaining('must not be later than'), findsOneWidget);
  });
}
