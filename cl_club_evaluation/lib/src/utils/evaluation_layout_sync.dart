import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationTemplatesMasterNotifier;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:ui_lib/ui_lib.dart'
    show EvaluationItemValue, EvaluationLayoutEntry;

import '../models/evaluation_layout_adapter.dart';
import '../models/evaluation_template_form_submit.dart';

/// Turns one change of the layout editor on a saved template into the
/// atomic writes the server takes: an added item is `addItem` (into its
/// section), a deleted one `removeItem`, an edited one `replaceItem`, and a
/// reorder, regroup or retitle `updateLayout`.
abstract final class EvaluationLayoutSync {
  /// Writes the change from [before] to [after] to template [templateId].
  static Future<void> apply({
    required int templateId,
    required List<EvaluationLayoutEntry> before,
    required List<EvaluationLayoutEntry> after,
    required ClEvaluationTemplatesMasterNotifier notifier,
  }) async {
    final old = {
      for (final i in EvaluationLayoutEntry.flatten(before)) ?i.id: i,
    };
    final now = EvaluationLayoutEntry.flatten(after);
    final kept = {for (final i in now) ?i.id};
    for (final id in old.keys.where((id) => !kept.contains(id))) {
      await EvaluationTemplateFormSubmit.removeItem(
        templateId: templateId,
        itemId: id,
        notifier: notifier,
      );
    }
    for (final item in now) {
      final was = old[item.id];
      if (was != null && was != item) {
        await EvaluationTemplateFormSubmit.replaceItem(
          templateId: templateId,
          item: item,
          notifier: notifier,
        );
      }
    }
    final added = [
      for (final i in now)
        if (i.id == null) i,
    ];
    for (final item in added) {
      await EvaluationTemplateFormSubmit.addItem(
        templateId: templateId,
        item: item,
        section: sectionOf(after, item),
        notifier: notifier,
      );
    }
    if (added.isNotEmpty) return;
    final expected = EvaluationLayoutAdapter.toIdLayout(
      withoutItems(before, old.keys.toSet().difference(kept)),
    );
    final desired = EvaluationLayoutAdapter.toIdLayout(after);
    if (!listEquals(expected, desired)) {
      await EvaluationTemplateFormSubmit.updateLayout(
        templateId: templateId,
        layout: after,
        notifier: notifier,
      );
    }
  }

  /// The title of the section of [layout] holding [item], or `null` when
  /// it sits outside any section.
  static String? sectionOf(
    List<EvaluationLayoutEntry> layout,
    EvaluationItemValue item,
  ) {
    for (final entry in layout) {
      if (entry.isSection &&
          entry.sectionItems.any((i) => identical(i, item))) {
        return entry.sectionTitle;
      }
    }
    return null;
  }

  /// [layout] as the server leaves it after removing items [ids]: their
  /// entries gone, sections kept.
  static List<EvaluationLayoutEntry> withoutItems(
    List<EvaluationLayoutEntry> layout,
    Set<int> ids,
  ) => [
    for (final entry in layout)
      if (entry.isSection)
        entry.copyWith(
          sectionItems: [
            for (final i in entry.sectionItems)
              if (!ids.contains(i.id)) i,
          ],
        )
      else if (!ids.contains(entry.item!.id))
        entry,
  ];
}
