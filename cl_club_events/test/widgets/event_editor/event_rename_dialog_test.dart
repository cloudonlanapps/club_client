import 'package:cl_club_events/src/widgets/event_editor/event_rename_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show RenameFormFields;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Opens the dialog over [initialTitle]; the list fills with what it
/// resolves to once it closes.
Future<List<String?>> _open(WidgetTester tester, String initialTitle) async {
  final results = <String?>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ShadButton(
            onPressed: () async =>
                results.add(await showEventRenameDialog(context, initialTitle)),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return results;
}

Finder _field() => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == RenameFormFields.valueId,
);

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 55: the event rename dialog reads the form values', () {
    testWidgets('Issue 55: Save resolves to the new name, trimmed', (
      tester,
    ) async {
      final results = await _open(tester, 'Summer Camp');
      expect(find.text('Event name *'), findsOneWidget);

      await tester.enterText(_field(), '  Winter Camp ');
      await _save(tester);

      expect(results, ['Winter Camp']);
    });

    testWidgets('Issue 55: Save on an unchanged name resolves to null', (
      tester,
    ) async {
      final results = await _open(tester, 'Summer Camp');

      await _save(tester);

      expect(results, [null]);
    });

    testWidgets('Issue 55: Save on an empty name keeps the dialog open with '
        'the message on the field', (tester) async {
      final results = await _open(tester, 'Summer Camp');

      await tester.enterText(_field(), '');
      await _save(tester);

      expect(results, isEmpty);
      expect(find.text('Rename event'), findsOneWidget);
      expect(find.textContaining('required'), findsOneWidget);
    });
  });
}
