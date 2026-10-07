import 'package:cl_calendar/cl_calendar.dart' show CLDatePicker;
import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form_harness.dart';

/// Checks shared by the tests of the credit, group, venue, location, rename,
/// club identity and consent forms, on top of `form_harness.dart`.

/// The one `ShadForm` on screen.
ShadFormState formOf(WidgetTester tester) =>
    tester.state<ShadFormState>(find.byType(ShadForm));

/// [message] shown on the field with [id], and nowhere else.
void expectFieldError(String id, String message) {
  expect(
    find.descendant(of: fieldWithId(id), matching: find.text(message)),
    findsOneWidget,
    reason: '"$message" on field "$id"',
  );
  expect(find.text(message), findsOneWidget, reason: '"$message" shown once');
}

/// Picks the option labelled [to] in the select now showing [from].
Future<void> pickOption(
  WidgetTester tester, {
  required String from,
  required String to,
}) async {
  await tester.tap(find.text(from));
  await tester.pumpAndSettle();
  await tester.tap(find.text(to).last);
  await tester.pumpAndSettle();
}

/// Picks [date] in the calendar of the date field with [id], as a tap on
/// that day does. (The calendar itself is cl_calendar's, and is not opened.)
Future<void> pickDate(WidgetTester tester, String id, DateTime date) async {
  tester
      .widget<CLDatePicker>(
        find.descendant(
          of: fieldWithId(id),
          matching: find.byType(CLDatePicker),
        ),
      )
      .onDateSelected(date);
  await tester.pumpAndSettle();
}

/// With `enabled: false` no field of the mounted form responds: every field
/// is off, a tap on each one opens no keyboard, and the taps leave the
/// form's values as they were.
Future<void> expectNoFieldResponds(WidgetTester tester) async {
  final form = formOf(tester);
  expect(form.fields, isNotEmpty);
  expect(
    [
      for (final entry in form.fields.entries)
        if (entry.value.enabled) entry.key,
    ],
    isEmpty,
    reason: 'fields still on',
  );

  final before = Map<String, dynamic>.of(form.value);
  final fields = find.byWidgetPredicate((w) => w is ShadFormBuilderField);
  final count = fields.evaluate().length;
  for (var i = 0; i < count; i++) {
    await tester.tap(fields.at(i), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
      tester.testTextInput.hasAnyClients,
      isFalse,
      reason: 'a tap on field $i opened the keyboard',
    );
  }
  expect(form.value, before, reason: 'a tap changed a value');
}

/// The form takes what the server refused and can be saved again: a message
/// on [fieldId] and one inline show, and the next `validate()` returns the
/// values with both messages gone. The form must hold valid values.
Future<Map<String, dynamic>> expectSavesAfterRefusal(
  WidgetTester tester,
  FormContract state,
  String fieldId,
) async {
  const onField = 'Refused by the server.';
  const onForm = 'Could not save.';
  state.showErrors(fieldErrors: {fieldId: onField}, formError: onForm);
  await tester.pumpAndSettle();
  expectFieldError(fieldId, onField);
  expect(find.text(onForm), findsOneWidget);

  final values = state.validate();
  await tester.pumpAndSettle();
  expect(values, isNotNull, reason: 'validate after a refusal');
  expect(find.text(onField), findsNothing);
  expect(find.text(onForm), findsNothing);
  return values!;
}

/// A bare `ShadForm` around what [builder] builds, for testing a field
/// cluster on its own. Builds the cluster again when a value changes, as a
/// form that embeds one does.
class ClusterHost extends StatefulWidget {
  const ClusterHost({
    required this.formKey,
    required this.builder,
    this.initialValue = const {},
    this.enabled = true,
    super.key,
  });

  /// Key of the host's `ShadForm`.
  final GlobalKey<ShadFormState> formKey;

  /// What the form starts with.
  final Map<String, dynamic> initialValue;

  /// The form's own `enabled`.
  final bool enabled;

  /// Builds the cluster under test.
  final WidgetBuilder builder;

  @override
  State<ClusterHost> createState() => _ClusterHostState();
}

class _ClusterHostState extends State<ClusterHost> {
  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: widget.formKey,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      onChanged: () => setState(() {}),
      child: Builder(builder: widget.builder),
    );
  }
}
