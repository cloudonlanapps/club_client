import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart' show RenameFormFields;
import 'package:cl_club_venues/src/widgets/venue_rename_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/dialog_dismissal.dart';

const _refused = 'That name cannot be used.';
const _initial = 'Summer Camp';

/// Opens the dialog over [_initial]. [onSave] answers each save; the lists
/// fill with the names sent to it and with what the dialog resolves to once
/// it closes.
Future<({List<String?> results, List<String> saved})> _open(
  WidgetTester tester, {
  Future<String?> Function(String name)? onSave,
}) async {
  final results = <String?>[];
  final saved = <String>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ShadButton(
            onPressed: () async => results.add(
              await showVenueRenameDialog(
                context,
                _initial,
                onSave: (name) async {
                  saved.add(name);
                  return onSave?.call(name);
                },
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (results: results, saved: saved);
}

Finder _field() => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == RenameFormFields.valueId,
);

ShadButton _button(WidgetTester tester, String label) =>
    tester.widget<ShadButton>(find.widgetWithText(ShadButton, label));

/// Presses Enter in the field, by its own callback: a field that is turned
/// off holds no text input connection to send the key through.
void _pressEnter(WidgetTester tester) => tester
    .widget<ShadInput>(
      find.descendant(of: _field(), matching: find.byType(ShadInput)),
    )
    .onSubmitted
    ?.call('');

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 113: the venue rename dialog stays open while it saves', () {
    testWidgets('Issue 113: while the venue rename dialog saves, its X, a tap '
        'outside, Escape and system back do not close it; once the name is '
        'refused the message shows and Escape closes it', (tester) async {
      final answer = Completer<String?>();
      final host = await _open(tester, onSave: (_) => answer.future);

      await tester.enterText(_field(), 'Winter Camp');
      await tester.tap(find.text('Save'));
      await tester.pump();

      await expectNoDismissal(tester, _field());
      expect(host.saved, ['Winter Camp']);
      expect(host.results, isEmpty);

      answer.complete(_refused);
      await tester.pumpAndSettle();
      expect(find.text(_refused), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_field(), findsNothing);
      expect(host.results, [null]);
    });
  });

  group('Issue 95: the venue rename dialog saves while it is open', () {
    testWidgets('Issue 95: a refused name leaves the venue rename dialog open '
        'with the typed name and the message on the field', (tester) async {
      final host = await _open(tester, onSave: (_) async => _refused);

      await tester.enterText(_field(), 'Winter Camp');
      await _save(tester);

      expect(host.saved, ['Winter Camp']);
      expect(host.results, isEmpty);
      expect(find.text(_refused), findsOneWidget);
      expect(find.text('Winter Camp'), findsOneWidget);
      expect(tester.widget<ShadInputFormField>(_field()).enabled, isTrue);
    });

    testWidgets('Issue 95: a saved name closes the venue rename dialog and '
        'resolves to it, trimmed', (tester) async {
      final host = await _open(tester);

      await tester.enterText(_field(), '  Winter Camp ');
      await _save(tester);

      expect(host.saved, ['Winter Camp']);
      expect(host.results, ['Winter Camp']);
    });

    testWidgets(
      'Issue 95: an unchanged name sends no save from the venue rename '
      'dialog and resolves to null',
      (tester) async {
        final host = await _open(tester);

        await _save(tester);

        expect(host.saved, isEmpty);
        expect(host.results, [null]);
      },
    );

    testWidgets(
      'Issue 95: while the venue rename dialog saves, the form is off '
      'and Save, Cancel and Enter do nothing; one save is sent',
      (
        tester,
      ) async {
        final answer = Completer<String?>();
        final host = await _open(tester, onSave: (_) => answer.future);

        await tester.enterText(_field(), 'Winter Camp');
        await tester.tap(find.text('Save'));
        await tester.pump();

        expect(tester.widget<ShadInputFormField>(_field()).enabled, isFalse);
        expect(_button(tester, 'Save').onPressed, isNull);
        expect(_button(tester, 'Cancel').onPressed, isNull);

        await tester.tap(find.text('Save'), warnIfMissed: false);
        await tester.tap(find.text('Cancel'), warnIfMissed: false);
        _pressEnter(tester);
        await tester.pump();

        expect(host.saved, ['Winter Camp']);
        expect(host.results, isEmpty);
        expect(_field(), findsOneWidget);

        answer.complete(null);
        await tester.pumpAndSettle();

        expect(host.saved, ['Winter Camp']);
        expect(host.results, ['Winter Camp']);
        expect(_field(), findsNothing);
      },
    );

    testWidgets(
      'Issue 95: Enter pressed twice in the venue rename dialog sends '
      'one save',
      (tester) async {
        final answer = Completer<String?>();
        final host = await _open(tester, onSave: (_) => answer.future);

        await tester.enterText(_field(), 'Winter Camp');
        _pressEnter(tester);
        _pressEnter(tester);
        await tester.pump();

        expect(host.saved, ['Winter Camp']);

        answer.complete(_refused);
        await tester.pumpAndSettle();

        expect(host.results, isEmpty);
        expect(find.text(_refused), findsOneWidget);
        expect(_button(tester, 'Save').onPressed, isNotNull);
        expect(_button(tester, 'Cancel').onPressed, isNotNull);
      },
    );
  });
}
