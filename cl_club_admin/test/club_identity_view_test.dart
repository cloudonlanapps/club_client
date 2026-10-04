import 'package:cl_club_admin/cl_club_admin.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clClubIdentityMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/admin_test_scope.dart';

const _stored = ClubIdentity(
  name: 'Example Club',
  contact: ClubContactDetails(
    phoneNumber: '+10000000000',
    city: LocalizedText('Example City', {'mr': 'Udaharan'}),
  ),
  extra: {'values': <String>[]},
);

Future<StubClubIdentity> _pump(
  WidgetTester tester, {
  ClubIdentity saved = _stored,
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 5000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = StubClubIdentity(saved);
  await tester.pumpWidget(
    adminScope(
      overrides: [clClubIdentityMasterProvider.overrideWith(() => stub)],
      child: ClubIdentityView(currentUser: adminViewer(superAdmin: true)),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

Finder _input(String id) => find.descendant(
  of: find.byKey(ValueKey('clubIdentity.$id')),
  matching: find.byType(EditableText),
);

Finder get _saveButton => find.byKey(const ValueKey('clubIdentity.save'));

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<ShadButton>(_saveButton).onPressed != null;

Future<void> _enter(WidgetTester tester, String id, String text) async {
  await tester.enterText(_input(id), text);
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(_saveButton);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 20: the club details screen', () {
    testWidgets('Issue 20: shows the stored identity; Save waits for an '
        'edit', (tester) async {
      await _pump(tester);

      expect(find.text('Club details'), findsOneWidget);
      expect(find.text('Example Club'), findsOneWidget);
      expect(find.text('+10000000000'), findsOneWidget);
      expect(find.text('Udaharan'), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);

      await _enter(tester, 'shortName', 'EXC');
      expect(_saveEnabled(tester), isTrue);
    });

    testWidgets('Issue 20: Save writes the whole document once, unknown '
        'keys kept', (tester) async {
      final stub = await _pump(tester);

      await _enter(tester, 'shortName', 'EXC');
      await _enter(tester, 'inquiryEmail', 'desk@club.example');
      await _save(tester);

      final saved = stub.saves.single;
      expect(saved.name, 'Example Club');
      expect(saved.shortName, 'EXC');
      expect(saved.inquiryEmail, 'desk@club.example');
      expect(
        saved.contact?.city,
        const LocalizedText('Example City', {'mr': 'Udaharan'}),
      );
      expect(saved.extra, _stored.extra);
      expect(find.text('Club details saved.'), findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('Issue 20: an invalid field blocks the save', (tester) async {
      final stub = await _pump(tester);

      await _enter(tester, 'phoneNumber', '98765 43210');
      await _save(tester);

      expect(stub.saves, isEmpty);
      expect(find.textContaining('international format'), findsOneWidget);
    });

    testWidgets('Issue 20: a refused save says so and keeps the edits', (
      tester,
    ) async {
      final stub = await _pump(tester)
        ..refuseWith = const ServerException(
          statusCode: 422,
          code: 'VALIDATION_ERROR',
          message: 'bad',
        );

      await _enter(tester, 'shortName', 'EXC');
      await _save(tester);

      expect(stub.saves, isEmpty);
      expect(
        find.text('Could not save the club details. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('EXC'), findsOneWidget);
    });

    testWidgets('Issue 20: Discard puts back what is saved', (tester) async {
      await _pump(tester);

      await _enter(tester, 'name', 'Other Club');
      await tester.tap(find.byKey(const ValueKey('clubIdentity.discard')));
      await tester.pumpAndSettle();

      expect(find.text('Example Club'), findsOneWidget);
      expect(find.text('Other Club'), findsNothing);
      expect(_saveEnabled(tester), isFalse);
    });
  });
}
