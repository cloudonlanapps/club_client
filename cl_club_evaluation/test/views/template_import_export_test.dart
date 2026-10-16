import 'dart:convert';
import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_club_evaluation/src/models/evaluation_template_file.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

final sdk.EvaluationTemplate _skating = template(
  1,
  layout: const [
    sdk.EvaluationLayoutSection('Edges', [11]),
    sdk.EvaluationLayoutItem(12),
  ],
  items: const [
    sdk.EvaluationRatingItem(
      id: 11,
      question: 'Inside edges',
      rateType: sdk.EvaluationRateType.stars,
      rateMin: 1,
      rateMax: 5,
    ),
    sdk.EvaluationQaItem(id: 12, question: 'Stride'),
  ],
);

const sdk.ServerException _nameTaken = sdk.ServerException(
  statusCode: 422,
  code: 'TEMPLATE_NAME_TAKEN',
  message: 'raw name taken',
);

/// [_skating] as the bytes of its export file.
Uint8List _skatingFile() =>
    utf8.encode(EvaluationTemplateFile.encode(_skating));

/// The template library over [stub], importing through [pick] into
/// [imported].
Widget _library(
  StubTemplates stub, {
  required Future<Uint8List?> Function() pick,
  required List<Map<String, dynamic>> imported,
}) => evaluationScope(
  templates: stub,
  child: TemplateLibraryView(
    currentUser: viewer('kim', coach: true),
    onOpenTemplate: (_) {},
    onCreateTemplate: () {},
    onDuplicateTemplate: (_) {},
    onPickTemplateFile: pick,
    onImportTemplate: imported.add,
  ),
);

/// The designer over [stub], pre-filled with [values].
Widget _designer(StubTemplates stub, Map<String, dynamic> values) =>
    evaluationScope(
      templates: stub,
      child: TemplateCreateView(
        currentUser: viewer('kim', coach: true),
        initialValues: values,
        onCreated: (_) {},
        onCancel: () {},
      ),
    );

void main() {
  group('Issue 27: Import', () {
    testWidgets('Issue 27: a template file opens the designer pre-filled, '
        'and Create makes the template with new items', (tester) async {
      final stub = StubTemplates({});
      final imported = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        _library(stub, pick: () async => _skatingFile(), imported: imported),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      expect(imported, hasLength(1));
      expect(stub.calls, isEmpty);

      await tallSurface(tester);
      await tester.pumpWidget(_designer(stub, imported.single));
      await tester.pumpAndSettle();
      expect(find.text('Skating'), findsOneWidget);
      expect(find.text('Edges'), findsOneWidget);
      expect(find.text('Inside edges'), findsOneWidget);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['create Skating 2']);
      final layout = stub.createdLayout!;
      expect(layout.first, isA<sdk.EvaluationLayoutSection<Object?>>());
      expect(
        [for (final e in layout) ...e.items.map((i) => i.id)],
        [
          null,
          null,
        ],
      );
    });

    testWidgets('Issue 27: an imported name already taken shows inline', (
      tester,
    ) async {
      final stub = StubTemplates({}, failWith: _nameTaken);
      await tallSurface(tester);
      await tester.pumpWidget(
        _designer(stub, EvaluationTemplateFile.initialValues(_skatingFile())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(
        find.text('A template with this name already exists.'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 27: a file that is not a template is refused with a '
        'message, and nothing opens', (tester) async {
      final imported = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        _library(
          StubTemplates({}),
          pick: () async => utf8.encode('{"format": "other"}'),
          imported: imported,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      expect(find.text('This file is not a review template.'), findsOneWidget);
      expect(imported, isEmpty);
    });

    testWidgets('Issue 27: no file chosen does nothing', (tester) async {
      final imported = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        _library(StubTemplates({}), pick: () async => null, imported: imported),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      expect(imported, isEmpty);
    });
  });

  group('Issue 27: Export', () {
    testWidgets('Issue 27: a template in use saves its file, named after '
        'it', (tester) async {
      final saved = <(String, Uint8List)>[];
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating.copyWith(inUse: true)}),
          child: TemplateDetailView(
            currentUser: viewer('kim', coach: true),
            templateId: 1,
            onBack: () {},
            onDuplicate: (_) {},
            onSaveTemplateFile: (name, bytes) async {
              saved.add((name, bytes));
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(saved, hasLength(1));
      expect(saved.single.$1, 'Skating.json');
      expect(
        utf8.decode(saved.single.$2),
        EvaluationTemplateFile.encode(
          _skating.copyWith(inUse: true),
        ),
      );
      expect(find.text('Template exported.'), findsOneWidget);
    });

    testWidgets('Issue 27: a failed save says so', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: _skating}),
          child: TemplateDetailView(
            currentUser: viewer('kim', coach: true),
            templateId: 1,
            onBack: () {},
            onDuplicate: (_) {},
            onSaveTemplateFile: (_, _) async => throw Exception('disk full'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(find.text('The template could not be exported.'), findsOneWidget);
    });
  });
}
