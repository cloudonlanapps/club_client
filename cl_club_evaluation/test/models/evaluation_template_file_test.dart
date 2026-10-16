import 'dart:convert';

import 'package:cl_club_evaluation/src/models/evaluation_layout_adapter.dart';
import 'package:cl_club_evaluation/src/models/evaluation_template_file.dart';
import 'package:cl_club_evaluation/src/models/template_file_exception.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

/// One item of every variant and every rating scale, as the server
/// returns them: with ids, and one copied question with an origin.
const List<sdk.EvaluationTemplateItem> _items = [
  sdk.EvaluationInfoItem(id: 1, markdown: 'Rate **this term**.'),
  sdk.EvaluationRatingItem(
    id: 2,
    question: 'Effort',
    isRequired: true,
    allowEvidence: true,
    showCommentArea: true,
    requireCommentFor: [1],
    rateType: sdk.EvaluationRateType.stars,
    rateMin: 1,
    rateMax: 5,
  ),
  sdk.EvaluationRatingItem(
    id: 3,
    question: 'Balance',
    rateMin: 1,
    rateMax: 10,
    originItemId: 40,
  ),
  sdk.EvaluationRatingItem(
    id: 4,
    question: 'Forward stride',
    isPrivate: true,
    showCommentArea: true,
    requireCommentFor: [1, 2],
    rateValues: [
      sdk.EvaluationRateLevel(value: 1, text: 'Needs work'),
      sdk.EvaluationRateLevel(value: 2, text: 'Good'),
    ],
  ),
  sdk.EvaluationYesNoItem(
    id: 5,
    question: 'Stops on both sides',
    showCommentArea: true,
    requireCommentFor: [false],
    labelTrue: 'Always',
    labelFalse: 'Not yet',
  ),
  sdk.EvaluationSingleChoiceItem(
    id: 6,
    question: 'Position',
    showCommentArea: true,
    requireCommentFor: ['goalie'],
    choices: [
      sdk.EvaluationChoice(value: 'forward', text: 'Forward'),
      sdk.EvaluationChoice(value: 'goalie', text: 'Goalie'),
    ],
  ),
  sdk.EvaluationMultipleChoiceItem(
    id: 7,
    question: 'Strong areas',
    allowEvidence: true,
    choices: [
      sdk.EvaluationChoice(value: 'edges', text: 'Edges'),
      sdk.EvaluationChoice(value: 'crossovers', text: 'Crossovers'),
    ],
  ),
  sdk.EvaluationNumberItem(
    id: 8,
    question: 'Laps',
    showCommentArea: true,
    requireCommentFor: [0],
  ),
  sdk.EvaluationQaItem(id: 9, question: 'What next', isRequired: true),
];

/// A template laying [_items] out as a loose info text, two sections and a
/// closing Q & A.
final sdk.EvaluationTemplate _template = sdk.EvaluationTemplate(
  id: 12,
  name: 'Ice Hockey Goalie Review',
  createdBy: 'kim',
  layout: const [
    sdk.EvaluationLayoutItem(1),
    sdk.EvaluationLayoutSection('Skating', [2, 3, 4]),
    sdk.EvaluationLayoutSection('Game sense', [5, 6, 7, 8]),
    sdk.EvaluationLayoutItem(9),
  ],
  items: _items,
  inUse: true,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026, 2),
);

/// [source] as file bytes.
List<int> _bytes(String source) => utf8.encode(source);

/// The message [source] is refused with.
String _refusal(String source) {
  try {
    EvaluationTemplateFile.initialValues(_bytes(source));
  } on TemplateFileException catch (e) {
    return e.message;
  }
  fail('$source was not refused');
}

void main() {
  group('Issue 27: EvaluationTemplateFile', () {
    test('Issue 27: an export holds the envelope, the name and the layout '
        'with items inline, and no ids, origins or server fields', () {
      final file =
          json.decode(EvaluationTemplateFile.encode(_template))
              as Map<String, dynamic>;
      expect(file.keys, ['format', 'version', 'name', 'layout']);
      expect(file['format'], 'club.evaluationTemplate');
      expect(file['version'], 1);
      expect(file['name'], 'Ice Hockey Goalie Review');
      final layout = file['layout'] as List<dynamic>;
      expect(layout, hasLength(4));
      expect((layout[1] as Map)['section'], 'Skating');
      final items = [
        layout.first,
        ...(layout[1] as Map)['items'] as List,
        ...(layout[2] as Map)['items'] as List,
        layout.last,
      ].cast<Map<String, dynamic>>();
      expect(items.map((i) => i['type']), [
        'info',
        'rating',
        'rating',
        'rating',
        'yesNo',
        'singleChoice',
        'multipleChoice',
        'number',
        'qa',
      ]);
      for (final item in items) {
        expect(item.containsKey('id'), isFalse);
        expect(item.containsKey('originItemId'), isFalse);
        expect(item.values, isNot(contains(null)));
      }
      expect(items[3]['isPrivate'], isTrue);
    });

    test('Issue 27: export then import gives the same template, its items '
        'new, over every item type and rating scale', () {
      final values = EvaluationTemplateFile.initialValues(
        _bytes(EvaluationTemplateFile.encode(_template)),
      );
      expect(
        values[EvaluationTemplateCreateFormFields.nameId],
        'Ice Hockey Goalie Review',
      );
      final layout =
          values[EvaluationTemplateCreateFormFields.layoutId]
              as List<EvaluationLayoutEntry>;
      for (final item in EvaluationLayoutEntry.flatten(layout)) {
        expect(item.id, isNull);
        expect(item.originItemId, isNull);
      }
      final created = EvaluationLayoutAdapter.toCreateLayout(layout);
      final expected = EvaluationLayoutAdapter.toCreateLayout([
        for (final entry in EvaluationLayoutAdapter.fromTemplate(
          _template.layout,
          _template.items,
        ))
          if (entry.isSection)
            EvaluationLayoutEntry.section(
              title: entry.sectionTitle!,
              items: [
                for (final i in entry.sectionItems)
                  i.copyWith(id: () => null, originItemId: () => null),
              ],
            )
          else
            EvaluationLayoutEntry.item(
              entry.item!.copyWith(id: () => null, originItemId: () => null),
            ),
      ]);
      expect(created, expected);
    });

    test('Issue 27: the file is named after the template', () {
      expect(
        EvaluationTemplateFile.fileName('Goalie: U12 / U14'),
        'Goalie_ U12 _ U14.json',
      );
      expect(EvaluationTemplateFile.fileName('???'), 'template.json');
    });

    test('Issue 27: a file that is not JSON is refused', () {
      expect(_refusal('{not json'), 'This file is not a JSON file.');
    });

    test('Issue 27: JSON that is not a template file is refused', () {
      const notTemplate = 'This file is not a review template.';
      expect(_refusal('[1, 2]'), notTemplate);
      expect(_refusal('{"format": "other", "version": 1}'), notTemplate);
      expect(
        _refusal(
          '{"format": "club.evaluationTemplate", "version": 1, '
          '"name": "A"}',
        ),
        notTemplate,
      );
    });

    test('Issue 27: a file of an unknown version is refused', () {
      expect(
        _refusal(
          '{"format": "club.evaluationTemplate", "version": 2, '
          '"name": "A", "layout": []}',
        ),
        'This template file is version 2, which this app cannot read.',
      );
    });

    test('Issue 27: a file with an item the app cannot read is refused, '
        'naming the entry', () {
      expect(
        _refusal(
          '{"format": "club.evaluationTemplate", "version": 1, '
          '"name": "A", "layout": [{"type": "qa", "question": "Q"}, '
          '{"section": "S", "items": [{"type": "slider"}]}]}',
        ),
        'Entry 2 of this template file cannot be read.',
      );
    });
  });
}
