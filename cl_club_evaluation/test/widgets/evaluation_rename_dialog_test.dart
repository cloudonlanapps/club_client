import 'package:cl_club_evaluation/src/widgets/evaluation_rename_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show RenameFormFields;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _taken = 'That name is taken.';

/// Opens the dialog over 'Skating'. [refuse] is what the save answers for a
/// name; the list fills with what the dialog resolves to once it closes.
Future<({List<String?> results, List<String> saved})> _open(
  WidgetTester tester, {
  String? Function(String name)? refuse,
}) async {
  final results = <String?>[];
  final saved = <String>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ShadButton(
            onPressed: () async => results.add(
              await showEvaluationRenameDialog(
                context,
                title: 'Rename template',
                label: 'Name',
                initial: 'Skating',
                onSave: (name) async {
                  saved.add(name);
                  return refuse?.call(name);
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

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 55: the evaluation rename dialog drives the form', () {
    testWidgets('Issue 55: a name the save refuses shows under the field '
        'and the dialog stays open', (tester) async {
      final host = await _open(tester, refuse: (_) => _taken);

      await tester.enterText(_field(), 'Hockey');
      await _save(tester);

      expect(host.saved, ['Hockey']);
      expect(host.results, isEmpty);
      expect(find.text(_taken), findsOneWidget);
      expect(find.text('Rename template'), findsOneWidget);
    });

    testWidgets('Issue 55: a saved name closes the dialog and resolves to '
        'it, trimmed', (tester) async {
      final host = await _open(tester);

      await tester.enterText(_field(), ' Hockey ');
      await _save(tester);

      expect(host.saved, ['Hockey']);
      expect(host.results, ['Hockey']);
    });

    testWidgets('Issue 55: an unchanged name writes nothing and resolves to '
        'null', (tester) async {
      final host = await _open(tester);

      await _save(tester);

      expect(host.saved, isEmpty);
      expect(host.results, [null]);
    });
  });
}
