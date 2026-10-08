import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/confirm_dialog.dart';

import '../support/dialog_dismissal.dart';

void main() {
  testWidgets('renders title and message', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: ConfirmDialog(
          title: 'Delete Data',
          message: 'Are you sure?',
          confirmLabel: 'Delete',
          onConfirm: () {},
        ),
      ),
    );
    expect(find.text('Delete Data'), findsOneWidget);
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('calls onConfirm when confirm clicked', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      ShadApp(
        home: ConfirmDialog(
          title: 'T',
          message: 'M',
          confirmLabel: 'Confirm',
          onConfirm: () => confirmed = true,
        ),
      ),
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(confirmed, true);
  });

  testWidgets('destructive flag uses destructive button', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: ConfirmDialog(
          title: 'T',
          message: 'M',
          confirmLabel: 'Confirm',
          destructive: true,
          onConfirm: () {},
        ),
      ),
    );
    expect(find.text('Confirm'), findsOneWidget);
  });
  testWidgets('Issue 113: while the password is checked, the X, a tap '
      'outside, Escape and system back do not close the confirm dialog', (
    tester,
  ) async {
    final checked = Completer<bool>();
    var confirmed = 0;
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ShadButton(
              onPressed: () => showShadDialog<void>(
                context: context,
                builder: (_) => ConfirmDialog(
                  title: 'Delete Data',
                  message: 'Are you sure?',
                  confirmLabel: 'Delete',
                  requiresPassword: true,
                  onVerifyPassword: (_) => checked.future,
                  onConfirm: () => confirmed++,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'secret');
    await tester.tap(find.text('Delete'));
    await tester.pump();

    await expectNoDismissal(tester, find.byType(ConfirmDialog));
    expect(confirmed, 0);

    checked.complete(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ConfirmDialog), findsNothing);
    expect(confirmed, 1);
  });
}
