import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

final sdk.EvaluationTemplate _skating = template(1);
final sdk.EvaluationTemplate _shooting = template(
  2,
  name: 'Shooting',
).copyWith(deletedAtUtc: () => t0);
final sdk.EvaluationTemplate _oldSkating = template(
  3,
).copyWith(deletedAtUtc: () => t0);

/// The library for [user] over [templates], [deleted] listed as deleted.
Future<void> _pumpLibrary(
  WidgetTester tester, {
  required StubTemplates templates,
  List<sdk.EvaluationTemplate> deleted = const [],
  sdk.UserPrivate? user,
}) async {
  await tester.pumpWidget(
    evaluationScope(
      templates: templates,
      deletedTemplates: deleted,
      child: TemplateLibraryView(
        currentUser: user ?? viewer('kim', coach: true),
        onOpenTemplate: (_) {},
        onCreateTemplate: () {},
        onDuplicateTemplate: (_) {},
        onPickTemplateFile: () async => null,
        onImportTemplate: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _showDeleted(WidgetTester tester) async {
  await tester.tap(find.text('Show deleted templates'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 277: deleted templates in the library', () {
    testWidgets('Issue 277: the switch lists the deleted templates, each '
        'with Restore, and back', (tester) async {
      await _pumpLibrary(
        tester,
        templates: StubTemplates({1: _skating, 2: _shooting}),
        deleted: [_shooting],
      );
      expect(find.text('Skating'), findsOneWidget);
      expect(find.text('Shooting'), findsNothing);
      expect(find.text('Restore'), findsNothing);

      await _showDeleted(tester);
      expect(find.text('Deleted templates'), findsOneWidget);
      expect(find.text('Shooting'), findsOneWidget);
      expect(find.text('Skating'), findsNothing);
      expect(find.text('Restore'), findsOneWidget);

      await _showDeleted(tester);
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Skating'), findsOneWidget);
      expect(find.text('Shooting'), findsNothing);
    });

    testWidgets('Issue 277: with no deleted template shows the empty state', (
      tester,
    ) async {
      await _pumpLibrary(tester, templates: StubTemplates({1: _skating}));
      await _showDeleted(tester);
      expect(find.text('No deleted templates.'), findsOneWidget);
    });

    testWidgets('Issue 277: Restore by an admin brings the template back to '
        'the library under its name', (tester) async {
      final stub = StubTemplates({1: _skating, 2: _shooting});
      await _pumpLibrary(
        tester,
        templates: stub,
        deleted: [_shooting],
        user: viewer('root', admin: true),
      );
      await _showDeleted(tester);

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(stub.calls, ['restore 2']);
      expect(find.text('Template restored.'), findsOneWidget);
      expect(find.text('No deleted templates.'), findsOneWidget);

      await _showDeleted(tester);
      expect(find.text('Shooting'), findsOneWidget);
    });

    testWidgets('Issue 277: a restore onto a taken name tells the new name', (
      tester,
    ) async {
      const renamed = 'Skating -- Restored #1';
      final stub = StubTemplates(
        {1: _skating, 3: _oldSkating},
        restoredNames: {3: renamed},
      );
      await _pumpLibrary(tester, templates: stub, deleted: [_oldSkating]);
      await _showDeleted(tester);

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(stub.calls, ['restore 3']);
      expect(
        find.text(
          'Template restored as "$renamed": its name is taken by another '
          'template.',
        ),
        findsOneWidget,
      );

      await _showDeleted(tester);
      expect(find.text('Skating'), findsOneWidget);
      expect(find.text(renamed), findsOneWidget);
    });

    testWidgets(
      'Issue 277: a refused restore keeps the row and says why, never '
      'with the raw error',
      (tester) async {
        final stub = StubTemplates(
          {1: _skating, 2: _shooting},
          failWith: const sdk.ServerException(
            statusCode: 422,
            code: 'NOTHING_TO_RESTORE',
            message: 'raw server text',
          ),
        );
        await _pumpLibrary(tester, templates: stub, deleted: [_shooting]);
        await _showDeleted(tester);

        await tester.tap(find.text('Restore'));
        await tester.pumpAndSettle();

        expect(stub.calls, ['restore 2']);
        expect(find.text('Template restored.'), findsNothing);
        expect(
          find.text('This template was already restored.'),
          findsOneWidget,
        );
        expect(find.textContaining('raw server text'), findsNothing);
        expect(find.text('Shooting'), findsOneWidget);
        expect(find.text('Restore'), findsOneWidget);
      },
    );
  });
}
