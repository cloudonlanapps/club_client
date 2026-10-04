import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  testWidgets('respects the initial value and returns it trimmed', (
    tester,
  ) async {
    final key = GlobalKey<RenameFormState>();
    await tester.pumpWidget(
      _wrap(
        RenameForm(key: key, initialValue: 'U12 Boys', label: 'Group Name'),
      ),
    );
    await tester.pumpAndSettle();

    // Field shows the initial value (not blank).
    expect(find.text('U12 Boys'), findsOneWidget);
    expect(key.currentState!.validate(), 'U12 Boys');
  });

  testWidgets('default validator rejects empty input', (tester) async {
    final key = GlobalKey<RenameFormState>();
    await tester.pumpWidget(
      _wrap(RenameForm(key: key, initialValue: '', label: 'Group Name')),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Group Name is required'), findsOneWidget);
  });

  testWidgets('honors a custom validator', (tester) async {
    final key = GlobalKey<RenameFormState>();
    await tester.pumpWidget(
      _wrap(
        RenameForm(
          key: key,
          initialValue: 'a',
          label: 'Venue name',
          validator: (v) =>
              v.trim().length < 2 ? 'At least 2 characters' : null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('At least 2 characters'), findsOneWidget);
  });
}
