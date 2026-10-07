import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form_harness.dart';

/// What the account, signup and user form tests share on top of
/// `form_harness.dart`.

final Finder _anyField = find.byWidgetPredicate(
  (widget) => widget is ShadFormBuilderField,
  description: 'any form field',
);

/// The ids of the fields on screen, top to bottom.
List<String> fieldIds(WidgetTester tester) => [
  for (final field in tester.widgetList<ShadFormBuilderField<dynamic>>(
    _anyField,
  ))
    field.id ?? '',
];

/// [message] shown on the field with [id], and nowhere else.
Finder messageOn(String id, String message) =>
    find.descendant(of: fieldWithId(id), matching: find.text(message));

/// [message] shows once, on the field with [id].
void expectMessageOn(String id, String message) {
  expect(messageOn(id, message), findsOneWidget, reason: '$id: $message');
  expect(find.text(message), findsOneWidget, reason: 'only on $id');
}

/// [message] shows once, inline: on no field.
void expectInlineMessage(String message) {
  expect(find.text(message), findsOneWidget);
  expect(
    find.descendant(of: _anyField, matching: find.text(message)),
    findsNothing,
    reason: 'the form-level message sits on no field',
  );
}

/// What the form holds for [id] now, valid or not.
Object? heldValue(FormContract state, String id) =>
    state.formKey.currentState!.value[id];

/// Every field on screen is off, and there is at least one.
void expectEveryFieldOff(WidgetTester tester) {
  final fields = tester.widgetList<ShadFormBuilderField<dynamic>>(_anyField);
  expect(fields, isNotEmpty);
  expect(
    [
      for (final field in fields)
        if (field.enabled) field.id,
    ],
    isEmpty,
    reason: 'fields still on',
  );
}

/// Whether the text field with [id] has the focus.
bool hasFocus(WidgetTester tester, String id) => tester
    .widget<EditableText>(
      find.descendant(of: fieldWithId(id), matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

/// Taps the text field with [id], as a member does to type into it.
Future<void> tapField(WidgetTester tester, String id) async {
  await tester.tap(
    find.descendant(of: fieldWithId(id), matching: find.byType(EditableText)),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
}

/// A tap on each text field of [ids] leaves it without the focus, so it
/// takes no typing. Not for a field that opens focused (`autofocus`).
Future<void> expectTapsIgnored(WidgetTester tester, List<String> ids) async {
  for (final id in ids) {
    await tapField(tester, id);
    expect(hasFocus(tester, id), isFalse, reason: '$id took the focus');
  }
}

/// Ticks or unticks the checkbox field with [id], as a member does.
Future<void> tapCheckbox(WidgetTester tester, String id) async {
  await tester.tap(
    find.descendant(of: fieldWithId(id), matching: find.byType(ShadCheckbox)),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
}

/// Taps the select with [id] where its value shows, as a member does to
/// open it.
Future<void> tapSelect(WidgetTester tester, String id) async {
  final select = find.descendant(
    of: fieldWithId(id),
    matching: find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString().startsWith('ShadSelect<'),
    ),
  );
  await tester.tapAt(tester.getTopLeft(select) + const Offset(24, 16));
  await tester.pumpAndSettle();
}

/// Opens the select with [id] and picks the option reading [option].
Future<void> pickOption(WidgetTester tester, String id, String option) async {
  await tapSelect(tester, id);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// The **Check availability** action of the username field.
final Finder checkAvailabilityButton = find.widgetWithText(
  ShadButton,
  'Check availability',
);

/// Whether the **Check availability** action responds.
bool checkAvailabilityIsOn(WidgetTester tester) =>
    tester.widget<ShadButton>(checkAvailabilityButton).onPressed != null;

/// Types [username] into the username field with [id] and runs its
/// availability check to the end.
Future<void> checkUsername(
  WidgetTester tester,
  String id,
  String username,
) async {
  await enterField(tester, id, username);
  await tester.tap(checkAvailabilityButton);
  await tester.pumpAndSettle();
}

/// Mounts [cluster], a group of fields that sits in a form, inside a bare
/// `ShadForm` seeded with [initial], and gives that form's state.
Future<ShadFormState> pumpCluster(
  WidgetTester tester,
  Widget cluster, {
  Map<String, dynamic> initial = const {},
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<ShadFormState>();
  await pumpForm(
    tester,
    ShadForm(key: key, initialValue: initial, child: cluster),
    size: size,
  );
  return key.currentState!;
}

/// The editable text of the text field with [id].
EditableText editableOf(WidgetTester tester, String id) =>
    tester.widget<EditableText>(
      find.descendant(of: fieldWithId(id), matching: find.byType(EditableText)),
    );

/// Whether the fields with ids [left] and [right] sit side by side, [left]
/// first; otherwise [right] is expected below [left], starting where it
/// starts.
bool sideBySide(WidgetTester tester, String left, String right) {
  final a = tester.getTopLeft(fieldWithId(left));
  final b = tester.getTopLeft(fieldWithId(right));
  if (b.dx > a.dx) return true;
  expect(b.dx, a.dx);
  expect(b.dy, greaterThan(a.dy));
  return false;
}
