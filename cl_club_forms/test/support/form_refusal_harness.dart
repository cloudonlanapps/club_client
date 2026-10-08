// The part of the form harness that plays a refused save: what a form does
// once its host has called `showErrors` and turned it on again.
import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form_harness.dart';

/// The order in which a host reports a refused save and turns its form on
/// again.
enum RefusalOrder {
  /// `showErrors`, then the form on, in one turn.
  errorsThenOn,

  /// `showErrors`, a frame, then the form on.
  errorsFrameThenOn,

  /// The form on, then `showErrors`, in one turn.
  onThenErrors,
}

/// A surface short enough that a long form scrolls.
const Size kShortSurface = Size(1024, 420);

/// The focus check of a form after a refused save, as a host in [order]
/// runs it: the form is turned off, `showErrors` is called and the form is
/// turned on again. [build] gives the same form with `enabled` on or off.
///
/// Each field refused alone takes the focus when it can; one with nothing
/// to focus is scrolled into view and the focus goes nowhere. Refused
/// together, the first field in the form's order is the one. After a
/// refusal that names no field the input that had the cursor has it again,
/// and the form-level message is on screen. Returns how many fields took
/// the focus.
Future<int> expectFocusAfterRefusal(
  WidgetTester tester,
  Widget Function({required bool enabled}) build, {
  required RefusalOrder order,
}) async {
  final enabled = ValueNotifier<bool>(true);
  addTearDown(enabled.dispose);
  await pumpForm(
    tester,
    ValueListenableBuilder<bool>(
      valueListenable: enabled,
      builder: (context, on, _) => build(enabled: on),
    ),
    size: kShortSurface,
  );
  final state = tester.allStates.whereType<FormContract>().first;
  final form = state.formKey.currentState!;
  final ids = form.fields.keys.toList();
  final view = find.byType(SingleChildScrollView).first;
  final scroll = tester.state<ScrollableState>(
    find.descendant(of: view, matching: find.byType(Scrollable)).first,
  );

  bool onScreen(Finder finder) =>
      tester.getRect(finder).overlaps(tester.getRect(view));

  Future<void> refuse(Map<String, String> fieldErrors, {String? formError}) {
    void show() =>
        state.showErrors(fieldErrors: fieldErrors, formError: formError);
    return () async {
      enabled.value = false;
      await tester.pumpAndSettle();
      expect(form.fields.values.every((f) => !f.enabled), isTrue);
      if (order != RefusalOrder.onThenErrors) show();
      if (order == RefusalOrder.errorsFrameThenOn) await tester.pump();
      enabled.value = true;
      if (order == RefusalOrder.onThenErrors) show();
      await tester.pumpAndSettle();
    }();
  }

  /// What the refusal of [id] must have done; true when it took the focus.
  bool expectActedOn(String id) {
    final field = form.fields[id]!;
    final node = field.focusNode;
    final typed =
        field.widget is ShadInputFormField ||
        field.widget is ShadTextareaFormField;
    // A field kept out of the focus order (a honeypot) is no input to act on.
    final open = field.enabled && node.canRequestFocus;
    if (typed && open && !field.widget.readOnly) {
      expect(node.hasFocus, isTrue, reason: 'field "$id" has no cursor');
    }
    if (node.context != null && open) {
      expect(node.hasFocus, isTrue, reason: 'field "$id" has no focus');
      return true;
    }
    expect(
      FocusManager.instance.primaryFocus,
      isA<FocusScopeNode>(),
      reason: 'field "$id" has nothing to focus, yet the focus moved',
    );
    final shown = fieldWithId(id);
    if (shown.evaluate().isNotEmpty && !tester.getSize(shown).isEmpty) {
      expect(onScreen(shown), isTrue, reason: 'field "$id" is off screen');
    }
    return false;
  }

  final textInputs = find.byType(EditableText);
  var focused = 0;
  for (final id in ids) {
    // As far from the field as the form scrolls.
    final shown = fieldWithId(id);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    if (shown.evaluate().isNotEmpty && onScreen(shown)) {
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await refuse({id: 'Refused by the server.'});
    if (expectActedOn(id)) focused++;
  }

  // Named last-to-first, the first field of the form is still the one.
  FocusManager.instance.primaryFocus?.unfocus();
  await refuse({for (final id in ids.reversed) id: 'Refused by the server.'});
  expectActedOn(ids.first);

  // A refusal that names no field: the cursor goes back where it was.
  const onForm = 'Could not save.';
  final inputs = textInputs.evaluate().length;
  for (var i = 0; i < inputs; i++) {
    await tester.showKeyboard(textInputs.at(i));
    await tester.pumpAndSettle();
    final cursor = tester.widget<EditableText>(textInputs.at(i)).focusNode;
    if (!cursor.hasFocus) continue;
    await refuse(const {}, formError: onForm);
    expect(cursor.hasFocus, isTrue, reason: 'input $i lost the cursor');
  }
  FocusManager.instance.primaryFocus?.unfocus();
  scroll.position.jumpTo(0);
  await refuse(const {}, formError: onForm);
  expect(onScreen(find.text(onForm)), isTrue, reason: 'message off screen');
  return focused;
}

/// The form-level message of a form goes on the next edit: `showErrors`
/// puts one inline, a field changes, and the message is gone. [build]
/// gives the form. The edit is typing into the first text input, or, where
/// that changes nothing, switching or emptying a field. Returns whether
/// the form had a field to edit.
Future<bool> expectFormErrorGoesOnEdit(
  WidgetTester tester,
  Widget Function({required bool enabled}) build,
) async {
  const onForm = 'Could not save.';
  await pumpForm(tester, build(enabled: true));
  final state = tester.allStates.whereType<FormContract>().first;
  final form = state.formKey.currentState!;
  state.showErrors(formError: onForm);
  await tester.pumpAndSettle();
  expect(find.text(onForm), findsOneWidget);
  // Frames alone, with nothing edited, leave the message.
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(onForm), findsOneWidget);

  // The first of these that changes a value is the edit.
  final typed = find.byWidgetPredicate(
    (w) => w is EditableText && !w.readOnly,
  );
  final before = Map<String, dynamic>.of(form.value);
  final edits = <Future<void> Function()>[
    if (typed.evaluate().isNotEmpty) ...[
      () => tester.enterText(typed.first, 'edited'),
      () => tester.enterText(typed.first, '7'),
    ],
    for (final field in form.fields.values)
      if (field.value case final bool on)
        () async => field.didChange(!on)
      else if (field.value != null)
        () async => field.didChange(null),
  ];
  var edited = false;
  for (final edit in edits) {
    await edit();
    await tester.pump();
    edited = !mapEquals(before, form.value);
    if (edited) break;
  }
  if (!edited) return false;
  await tester.pumpAndSettle();
  expect(find.text(onForm), findsNothing, reason: 'message stayed');
  return true;
}
