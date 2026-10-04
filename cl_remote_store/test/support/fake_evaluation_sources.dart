/// In-memory fake of `/evaluations` and its fixtures (club_core#173),
/// recording every call so a test can assert both the state a provider
/// holds and the SDK calls it made.
library;

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Capabilities with only the evaluations module switched as given.
class EvaluationCapabilities extends Fake implements CapabilitiesSource {
  EvaluationCapabilities({required this.evaluations});

  final bool evaluations;

  @override
  Future<Capabilities> getCapabilities() async =>
      Capabilities(evaluations: evaluations);
}

final DateTime fakeEvaluationTime = DateTime.utc(2026, 9);

/// A template named [name] holding [items], laid out flat; [inUse] when an
/// evaluation uses it.
EvaluationTemplate fakeTemplate(
  int id, {
  String name = 'Skating',
  List<EvaluationTemplateItem> items = const [],
  bool inUse = false,
  DateTime? deletedAtUtc,
}) => EvaluationTemplate(
  id: id,
  name: name,
  createdBy: 'admin',
  layout: [for (final i in items) EvaluationLayoutItem<int>(i.id!)],
  items: items,
  inUse: inUse,
  createdAtUtc: fakeEvaluationTime,
  updatedAtUtc: fakeEvaluationTime,
  deletedAtUtc: deletedAtUtc,
);

/// A staff view of a draft for [createdFor].
EvaluationStaffView fakeStaffView(
  int id, {
  String createdFor = 'member',
  EvaluationStatus status = EvaluationStatus.draft,
  List<EvaluationAnswer> answers = const [],
}) => EvaluationStaffView(
  id: id,
  templateId: 1,
  createdFor: createdFor,
  createdBy: 'coach',
  status: status,
  answers: answers,
  createdAtUtc: fakeEvaluationTime,
  updatedAtUtc: fakeEvaluationTime,
);

/// `/evaluations` over in-memory templates and evaluations.
class FakeEvaluations extends Fake implements EvaluationSource {
  final Map<int, EvaluationTemplate> templates = {};
  final Map<int, EvaluationStaffView> evaluations = {};
  final List<String> calls = [];
  List<EvaluationTemplateItemHit> hits = const [];

  /// Thrown by [saveEvaluation] when set.
  Exception? saveError;

  int _nextId = 100;

  PaginatedList<T> _page<T>(List<T> all, int offset, int limit) {
    final items = all.skip(offset).take(limit).toList();
    return PaginatedList(
      items: items,
      total: all.length,
      offset: offset,
      limit: limit,
    );
  }

  EvaluationStaffView _put(EvaluationStaffView view) =>
      evaluations[view.id] = view;

  EvaluationTemplate _putTemplate(EvaluationTemplate t) => templates[t.id] = t;

  // Evaluations.

  @override
  Future<PaginatedList<EvaluationStaffView>> listEvaluations({
    EvaluationStatus? status,
    String? createdFor,
    int? eventId,
    bool? general,
    int offset = 0,
    int limit = 20,
  }) async {
    calls.add('listEvaluations');
    return _page(evaluations.values.toList(), offset, limit);
  }

  @override
  Future<EvaluationStaffView> getEvaluation(int id) async {
    calls.add('getEvaluation $id');
    return evaluations[id]!;
  }

  @override
  Future<EvaluationStaffView> createEvaluation({
    required int templateId,
    required String createdFor,
    int? eventId,
    DateTime? periodStartUtc,
    DateTime? periodEndUtc,
  }) async {
    calls.add('createEvaluation $templateId $createdFor $eventId');
    return _put(
      fakeStaffView(
        _nextId++,
        createdFor: createdFor,
      ).copyWith(templateId: templateId, eventId: () => eventId),
    );
  }

  @override
  Future<EvaluationStaffView> updateEvaluation(
    int id, {
    int? Function()? eventId,
    DateTime? Function()? periodStartUtc,
    DateTime? Function()? periodEndUtc,
  }) async {
    String sent(Object? Function()? getter) =>
        getter == null ? '-' : '${getter()}';
    calls.add(
      'updateEvaluation $id event=${sent(eventId)} '
      'start=${sent(periodStartUtc)} end=${sent(periodEndUtc)}',
    );
    return _put(
      evaluations[id]!.copyWith(
        eventId: eventId,
        periodStartUtc: periodStartUtc,
        periodEndUtc: periodEndUtc,
      ),
    );
  }

  @override
  Future<EvaluationStaffView> putAnswer(
    int id,
    int itemId,
    EvaluationAnswerInput answer,
  ) async {
    calls.add('putAnswer $id $itemId');
    final view = evaluations[id]!;
    return _put(
      view.copyWith(
        answers: [
          ...view.answers.where((a) => a.itemId != itemId),
          EvaluationAnswer(
            itemId: itemId,
            valueNum: answer.valueNum,
            valueText: answer.valueText,
            coachNote: answer.coachNote,
          ),
        ],
      ),
    );
  }

  @override
  Future<EvaluationStaffView> clearAnswer(int id, int itemId) async {
    calls.add('clearAnswer $id $itemId');
    final view = evaluations[id]!;
    return _put(
      view.copyWith(
        answers: view.answers.where((a) => a.itemId != itemId).toList(),
      ),
    );
  }

  @override
  Future<EvaluationStaffView> uploadEvidence(
    int id,
    int itemId, {
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    calls.add('uploadEvidence $id $itemId $filename $contentType');
    final view = evaluations[id]!;
    final answer = view.answerFor(itemId) ?? EvaluationAnswer(itemId: itemId);
    return _put(
      view.copyWith(
        answers: [
          ...view.answers.where((a) => a.itemId != itemId),
          EvaluationAnswer(
            itemId: itemId,
            valueNum: answer.valueNum,
            valueText: answer.valueText,
            choices: answer.choices,
            coachNote: answer.coachNote,
            evidence: [
              ...answer.evidence,
              EvaluationEvidence(mediaUuid: 'uuid-$filename'),
            ],
          ),
        ],
      ),
    );
  }

  EvaluationStaffView _status(String call, int id, EvaluationStatus s) {
    calls.add('$call $id');
    return _put(evaluations[id]!.copyWith(status: s));
  }

  @override
  Future<EvaluationStaffView> saveEvaluation(int id) async {
    if (saveError != null) {
      calls.add('saveEvaluation $id');
      throw saveError!;
    }
    return _status('saveEvaluation', id, EvaluationStatus.saved);
  }

  @override
  Future<EvaluationStaffView> publishEvaluation(int id) async =>
      _status('publishEvaluation', id, EvaluationStatus.published);

  @override
  Future<EvaluationStaffView> unpublishEvaluation(int id) async =>
      _status('unpublishEvaluation', id, EvaluationStatus.saved);

  @override
  Future<EvaluationStaffView> revertEvaluation(int id) async =>
      _status('revertEvaluation', id, EvaluationStatus.draft);

  @override
  Future<void> transferEvaluation(int id, {required String owner}) async {
    calls.add('transferEvaluation $id $owner');
    evaluations.remove(id);
  }

  @override
  Future<EvaluationStaffView> deleteEvaluation(int id) async {
    calls.add('deleteEvaluation $id');
    return evaluations[id]!.copyWith(deletedAtUtc: () => fakeEvaluationTime);
  }

  @override
  Future<EvaluationStaffView> restoreEvaluation(int id) async {
    calls.add('restoreEvaluation $id');
    return _put(evaluations[id]!.copyWith(deletedAtUtc: () => null));
  }

  @override
  Future<List<int>> previewMemberCopy(int id) async {
    calls.add('previewMemberCopy $id');
    return const [0x25, 0x50, 0x44, 0x46];
  }

  // Templates.

  @override
  Future<PaginatedList<EvaluationTemplate>> listTemplates({
    int offset = 0,
    int limit = 20,
  }) async {
    calls.add('listTemplates $offset');
    return _page(templates.values.toList(), offset, limit);
  }

  @override
  Future<EvaluationTemplate> createTemplate({
    required String name,
    required List<EvaluationLayoutEntry<EvaluationTemplateItem>> layout,
  }) async {
    calls.add('createTemplate $name');
    var itemId = 500;
    final items = [
      for (final entry in layout)
        for (final item in entry.items) _withId(item, itemId++),
    ];
    return _putTemplate(fakeTemplate(_nextId++, name: name, items: items));
  }

  @override
  Future<EvaluationTemplate> updateTemplate(
    int id, {
    String? name,
    List<EvaluationLayoutEntry<int>>? layout,
  }) async {
    calls.add('updateTemplate $id ${name ?? ''} ${layout?.length ?? ''}');
    return _putTemplate(
      templates[id]!.copyWith(name: name, layout: layout),
    );
  }

  @override
  Future<EvaluationTemplate> addItem(
    int templateId,
    EvaluationTemplateItem item, {
    String? section,
  }) async {
    calls.add('addItem $templateId $section');
    final t = templates[templateId]!;
    final added = _withId(item, 900 + t.items.length);
    return _putTemplate(
      t.copyWith(
        items: [...t.items, added],
        layout: [...t.layout, EvaluationLayoutItem<int>(added.id!)],
      ),
    );
  }

  @override
  Future<EvaluationTemplate> replaceItem(
    int templateId,
    int itemId,
    EvaluationTemplateItem item,
  ) async {
    calls.add('replaceItem $templateId $itemId');
    final t = templates[templateId]!;
    return _putTemplate(
      t.copyWith(
        items: [
          for (final i in t.items)
            if (i.id == itemId) _withId(item, itemId) else i,
        ],
      ),
    );
  }

  @override
  Future<EvaluationTemplate> removeItem(int templateId, int itemId) async {
    calls.add('removeItem $templateId $itemId');
    final t = templates[templateId]!;
    return _putTemplate(
      t.copyWith(
        items: t.items.where((i) => i.id != itemId).toList(),
        layout: t.layout.where((e) => !e.items.contains(itemId)).toList(),
      ),
    );
  }

  @override
  Future<EvaluationTemplate> deleteTemplate(int id) async {
    calls.add('deleteTemplate $id');
    return templates[id]!.copyWith(deletedAtUtc: () => fakeEvaluationTime);
  }

  @override
  Future<EvaluationTemplate> restoreTemplate(int id) async {
    calls.add('restoreTemplate $id');
    return _putTemplate(templates[id]!.copyWith(deletedAtUtc: () => null));
  }

  @override
  Future<PaginatedList<EvaluationTemplateItemHit>> searchItems({
    String? search,
    EvaluationItemType? type,
    int offset = 0,
    int limit = 20,
  }) async {
    calls.add('searchItems ${search ?? ''} ${type?.wireName ?? ''}');
    return _page(hits, offset, limit);
  }

  static EvaluationTemplateItem _withId(EvaluationTemplateItem item, int id) =>
      switch (item) {
        EvaluationQaItem() => item.copyWith(id: () => id),
        _ => throw UnimplementedError('fake handles Q & A items only'),
      };
}
