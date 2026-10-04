import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _organizer = PickerUser(
  username: 'org',
  displayName: 'Olivia Organizer',
  isAdmin: true,
);
const _coachA = PickerUser(
  username: 'coach_a',
  displayName: 'Aaron Coach',
  isCoach: true,
);
const _coachB = PickerUser(
  username: 'coach_b',
  displayName: 'Bea Coach',
  isCoach: true,
);
const _coachC = PickerUser(
  username: 'coach_c',
  displayName: 'Cara Coach',
  isCoach: true,
);

OrganizerCoachesEditor _editor(
  GlobalKey<OrganizerCoachesEditorState> key, {
  PickerUser? transferTo,
  List<PickerUser> addCoaches = const [],
}) {
  return OrganizerCoachesEditor(
    key: key,
    initialOrganizer: _organizer,
    initialCoaches: const [_coachA, _coachB],
    onPickOrganizer: () async => transferTo,
    onPickCoaches: (exclude) async =>
        addCoaches.where((c) => !exclude.contains(c.username)).toList(),
  );
}

void main() {
  testWidgets('Issue 678: seeded organizer + coaches validate, start clean', (
    tester,
  ) async {
    final key = GlobalKey<OrganizerCoachesEditorState>();
    await tester.pumpWidget(_wrap(_editor(key)));
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values[EventFormFields.organizerNameId], 'org');
    expect(values[EventFormFields.coachNamesId], const ['coach_a', 'coach_b']);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets(
    'Issue 678: removing a coach strikes it through and is revertible',
    (
      tester,
    ) async {
      final key = GlobalKey<OrganizerCoachesEditorState>();
      await tester.pumpWidget(_wrap(_editor(key)));
      await tester.pumpAndSettle();

      // Remove the first coach (the ✕ ghost button on its row).
      await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).first);
      await tester.pumpAndSettle();

      // It's staged for removal: excluded from the value, dirty, Undo offered.
      expect(key.currentState!.isDirty, isTrue);
      expect(
        key.currentState!.validate()[EventFormFields.coachNamesId],
        const ['coach_b'],
      );
      expect(find.widgetWithText(ShadButton, 'Undo'), findsOneWidget);

      // Revert restores it and the form is clean again.
      await tester.tap(find.widgetWithText(ShadButton, 'Undo'));
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
      expect(
        key.currentState!.validate()[EventFormFields.coachNamesId],
        const ['coach_a', 'coach_b'],
      );
    },
  );

  testWidgets('Issue 678: Transfer changes the organizer', (tester) async {
    final key = GlobalKey<OrganizerCoachesEditorState>();
    await tester.pumpWidget(_wrap(_editor(key, transferTo: _coachC)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ShadButton, 'Transfer'));
    await tester.pumpAndSettle();

    expect(key.currentState!.isDirty, isTrue);
    expect(
      key.currentState!.validate()[EventFormFields.organizerNameId],
      'coach_c',
    );
  });

  testWidgets('Issue 678: Add coaches appends to the coach list', (
    tester,
  ) async {
    final key = GlobalKey<OrganizerCoachesEditorState>();
    await tester.pumpWidget(_wrap(_editor(key, addCoaches: const [_coachC])));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ShadButton, 'Add coaches'));
    await tester.pumpAndSettle();

    expect(key.currentState!.isDirty, isTrue);
    expect(
      key.currentState!.validate()[EventFormFields.coachNamesId],
      const ['coach_a', 'coach_b', 'coach_c'],
    );
  });
}
