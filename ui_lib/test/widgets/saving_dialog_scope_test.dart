import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show SavingDialogCloseIcon, SavingDialogScope;

import '../support/dialog_dismissal.dart';

const _title = 'A dialog';

/// Opens a dialog built with the scope and its close icon; [saving] says
/// whether its save is in flight. The list fills once the dialog closes.
Future<List<bool>> _open(WidgetTester tester, {required bool saving}) async {
  final closed = <bool>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ShadButton(
            onPressed: () async {
              await showShadDialog<void>(
                context: context,
                builder: (_) => SavingDialogScope(
                  saving: saving,
                  child: ShadDialog(
                    title: const Text(_title),
                    closeIcon: SavingDialogCloseIcon(saving: saving),
                    child: const Text('Body'),
                  ),
                ),
              );
              closed.add(true);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return closed;
}

void main() {
  testWidgets('Issue 113: a dialog in a saving scope is not closed by its X, '
      'a tap outside, Escape or system back', (tester) async {
    final closed = await _open(tester, saving: true);

    await expectNoDismissal(tester, find.text(_title));

    expect(closed, isEmpty);
  });

  for (final MapEntry(key: name, value: dismiss) in dismissals.entries) {
    testWidgets('Issue 113: a dialog whose save is not in flight is closed '
        'by $name', (tester) async {
      final closed = await _open(tester, saving: false);

      await dismiss(tester);
      await tester.pumpAndSettle();

      expect(find.text(_title), findsNothing);
      expect(closed, [true]);
    });
  }
}
