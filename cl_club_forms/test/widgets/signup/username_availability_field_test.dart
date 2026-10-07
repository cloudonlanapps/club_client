// UsernameAvailabilityField is one composite field, not a form: it has no
// row label of its own (the embedding form gives it one), no rule across
// fields and no values beyond the username it registers. What is tested
// here is the life of its availability check and what it tells its parent.
import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/signup/username_availability_field.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _id = UserFormFields.usernameId;
const _hint = 'Lowercase letters, digits, and _ only';
const _failed = 'Could not check availability. Try again.';

/// What the field told its parent: the username as typed and the one
/// confirmed.
typedef _Report = (String, String?);

class _Host {
  final formKey = GlobalKey<ShadFormState>();
  final fieldKey = GlobalKey<UsernameAvailabilityFieldState>();
  final reports = <_Report>[];
  final checked = <String>[];

  /// What a check resolves to; replaced by a test that holds it open.
  Future<bool> Function(String username) answer = (_) async => true;

  Widget build({bool enabled = true, String id = _id}) => ShadForm(
    key: formKey,
    child: UsernameAvailabilityField(
      key: fieldKey,
      id: id,
      enabled: enabled,
      validator: UserFormValidators.username,
      onAvailabilityChanged: (username, confirmed) =>
          reports.add((username, confirmed)),
      checkAvailability: (username) {
        checked.add(username);
        return answer(username);
      },
    ),
  );

  UsernameAvailabilityFieldState get state => fieldKey.currentState!;
}

Future<_Host> _pump(WidgetTester tester, {bool enabled = true}) async {
  final host = _Host();
  await pumpForm(tester, host.build(enabled: enabled));
  return host;
}

bool _inputIsOn(WidgetTester tester) =>
    tester.widget<ShadInputFormField>(fieldWithId(_id)).enabled;

void main() {
  group('Issue 61: UsernameAvailabilityField', () {
    testWidgets('Issue 61: idle, it shows its hint and offers no check '
        'below three characters', (tester) async {
      final host = await _pump(tester);

      expect(find.text(_hint), findsOneWidget);
      expect(checkAvailabilityButton, findsNothing);

      await enterField(tester, _id, 'ab');
      expect(checkAvailabilityButton, findsNothing);

      await enterField(tester, _id, 'abc');
      expect(checkAvailabilityButton, findsOneWidget);
      expect(checkAvailabilityIsOn(tester), isTrue);
      expect(find.text('Available'), findsNothing);
      expect(find.text('Already taken'), findsNothing);
      expect(host.checked, isEmpty, reason: 'nothing is checked unasked');
    });

    testWidgets('Issue 61: it keeps lowercase letters, digits and _ and '
        'drops everything else as typed', (tester) async {
      final host = await _pump(tester);

      await enterField(tester, _id, 'Ro-Bin 9_x!');

      expect(host.state.controller.text, 'oin9_x');
      expect(host.formKey.currentState!.value[_id], 'oin9_x');
    });

    testWidgets('Issue 61: it tells its parent each username as typed, none '
        'confirmed', (tester) async {
      final host = await _pump(tester);

      await enterField(tester, _id, 'rob');
      await enterField(tester, _id, 'robin');

      expect(
        host.reports,
        containsAllInOrder([('rob', null), ('robin', null)]),
      );
      expect(host.reports.every((report) => report.$2 == null), isTrue);
      expect(host.reports.last, ('robin', null));
    });

    testWidgets('Issue 61: checking, it shows progress and neither the input '
        'nor the action responds', (tester) async {
      final host = await _pump(tester);
      final answer = Completer<bool>();
      host.answer = (_) => answer.future;
      await enterField(tester, _id, 'robin');

      await tester.tap(checkAvailabilityButton);
      await tester.pump();

      expect(host.checked, ['robin']);
      expect(host.state.isChecking, isTrue);
      expect(find.text('Checking…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_inputIsOn(tester), isFalse);
      expect(checkAvailabilityIsOn(tester), isFalse);

      await tester.tap(checkAvailabilityButton, warnIfMissed: false);
      await tester.pump();
      expect(host.checked, ['robin'], reason: 'no second check meanwhile');

      answer.complete(true);
      await tester.pumpAndSettle();
      expect(host.state.isChecking, isFalse);
      expect(find.text('Checking…'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_inputIsOn(tester), isTrue);
    });

    testWidgets('Issue 61: available, it says so, confirms the username to '
        'its parent and offers no second check', (tester) async {
      final host = await _pump(tester);

      await checkUsername(tester, _id, 'robin');

      expect(find.text('Available'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(host.reports.last, ('robin', 'robin'));
      expect(host.state.confirmedAvailableUsername, 'robin');
      expect(checkAvailabilityIsOn(tester), isFalse);
    });

    testWidgets('Issue 61: taken, it says so, confirms nothing and lets the '
        'check run again', (tester) async {
      final host = await _pump(tester);
      host.answer = (_) async => false;

      await checkUsername(tester, _id, 'robin');

      expect(find.text('Already taken'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(find.text('Available'), findsNothing);
      expect(host.reports.last, ('robin', null));
      expect(host.state.confirmedAvailableUsername, isNull);
      expect(checkAvailabilityIsOn(tester), isTrue);
    });

    testWidgets('Issue 61: failed, it says the check could not run, confirms '
        'nothing, and a second try can succeed', (tester) async {
      final host = await _pump(tester);
      host.answer = (_) async => throw StateError('offline');

      await checkUsername(tester, _id, 'robin');

      expect(find.text(_failed), findsOneWidget);
      expect(find.textContaining('offline'), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
      expect(host.reports.last, ('robin', null));
      expect(_inputIsOn(tester), isTrue);
      expect(checkAvailabilityIsOn(tester), isTrue);

      host.answer = (_) async => true;
      await tester.tap(checkAvailabilityButton);
      await tester.pumpAndSettle();

      expect(host.checked, ['robin', 'robin']);
      expect(find.text(_failed), findsNothing);
      expect(find.text('Available'), findsOneWidget);
      expect(host.reports.last, ('robin', 'robin'));
    });

    testWidgets('Issue 61: editing a confirmed username takes the '
        'confirmation back, even when the same name is typed again', (
      tester,
    ) async {
      final host = await _pump(tester);
      await checkUsername(tester, _id, 'robin');

      await enterField(tester, _id, 'robin2');

      expect(find.text('Available'), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(host.reports.last, ('robin2', null));
      expect(checkAvailabilityIsOn(tester), isTrue);

      await enterField(tester, _id, 'robin');
      expect(find.text('Available'), findsNothing);
      expect(host.reports.last, ('robin', null));
      expect(host.checked, ['robin'], reason: 'no check runs by itself');
    });

    testWidgets('Issue 61: editing a taken username clears the verdict', (
      tester,
    ) async {
      final host = await _pump(tester);
      host.answer = (_) async => false;
      await checkUsername(tester, _id, 'robin');

      await enterField(tester, _id, 'robin2');

      expect(find.text('Already taken'), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    });

    testWidgets('Issue 61: editing after a failed check clears the failure', (
      tester,
    ) async {
      final host = await _pump(tester);
      host.answer = (_) async => throw StateError('offline');
      await checkUsername(tester, _id, 'robin');

      await enterField(tester, _id, 'robin2');

      expect(find.text(_failed), findsNothing);
    });

    testWidgets('Issue 61: a username its validator refuses is not sent to '
        'the check', (tester) async {
      final host = await _pump(tester);
      // Past the typing filter, as a paste the filter did not see would be.
      host.state.controller.text = 'Robin-K';
      await tester.pumpAndSettle();

      await tester.tap(checkAvailabilityButton);
      await tester.pumpAndSettle();

      expect(host.checked, isEmpty);
      expect(find.text('Available'), findsNothing);
      expect(host.state.confirmedAvailableUsername, isNull);
    });

    testWidgets('Issue 61: the form refuses a short username on the field', (
      tester,
    ) async {
      final host = await _pump(tester);
      await enterField(tester, _id, 'ab');

      expect(host.formKey.currentState!.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_id, 'At least 3 characters');

      await enterField(tester, _id, 'abc');
      expect(host.formKey.currentState!.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: with enabled off neither the input nor the '
        'action responds', (tester) async {
      final host = await _pump(tester);
      await enterField(tester, _id, 'robin');
      expect(checkAvailabilityIsOn(tester), isTrue);

      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: host.build(enabled: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(host.state.controller.text, 'robin', reason: 'the same field');
      expect(_inputIsOn(tester), isFalse);
      expect(checkAvailabilityIsOn(tester), isFalse);
      await tester.tap(checkAvailabilityButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(host.checked, isEmpty);
    });

    testWidgets('Issue 61: an answer that comes after the field is gone is '
        'dropped quietly', (tester) async {
      final host = await _pump(tester);
      final answer = Completer<bool>();
      host.answer = (_) => answer.future;
      await enterField(tester, _id, 'robin');
      await tester.tap(checkAvailabilityButton);
      await tester.pump();
      final reportsBefore = host.reports.length;

      await tester.pumpWidget(const SizedBox.shrink());
      answer.complete(true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(host.reports, hasLength(reportsBefore));
    });

    testWidgets('Issue 61: it registers under the id it is given', (
      tester,
    ) async {
      final host = _Host();
      await pumpForm(tester, host.build(id: 'handle'));

      await enterField(tester, 'handle', 'robin');

      expect(host.formKey.currentState!.value, {'handle': 'robin'});
    });

    testWidgets('Issue 61: it fits a phone with the check row and its '
        'longest message showing', (tester) async {
      final host = _Host()..answer = (_) async => throw StateError('offline');
      await expectFitsPhone(tester, host.build());

      await checkUsername(tester, _id, 'a_rather_long_username_for_a_phone');

      expect(find.text(_failed), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
