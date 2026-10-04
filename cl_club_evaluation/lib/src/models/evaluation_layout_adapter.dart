import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show EvaluationItemValue, EvaluationLayoutEntry;

import 'evaluation_item_adapter.dart';

/// The adapter between the SDK's template layout and the ui_lib form-local
/// layout (form rules 7, 18): a template read lays out item ids, a template
/// being created lays out its items inline.
abstract final class EvaluationLayoutAdapter {
  /// [layout] of item ids with each id replaced by its item from [items]
  /// (a template read, or the member's public template). Ids with no item
  /// are dropped.
  static List<EvaluationLayoutEntry> fromTemplate(
    List<sdk.EvaluationLayoutEntry<int>> layout,
    List<sdk.EvaluationTemplateItem> items,
  ) {
    final byId = <int, EvaluationItemValue>{
      for (final item in items) ?item.id: EvaluationItemAdapter.toValue(item),
    };
    return [
      for (final entry in layout)
        if (entry case sdk.EvaluationLayoutSection(:final section))
          EvaluationLayoutEntry.section(
            title: section,
            items: [
              for (final id in entry.items) ?byId[id],
            ],
          )
        else if (byId[entry.items.single] case final item?)
          EvaluationLayoutEntry.item(item),
    ];
  }

  /// [layout] with its items inline, for creating a template.
  static List<sdk.EvaluationLayoutEntry<sdk.EvaluationTemplateItem>>
  toCreateLayout(List<EvaluationLayoutEntry> layout) => [
    for (final entry in layout)
      if (entry.isSection)
        sdk.EvaluationLayoutSection(entry.sectionTitle!, [
          for (final item in entry.sectionItems)
            EvaluationItemAdapter.toSdk(item),
        ])
      else
        sdk.EvaluationLayoutItem(EvaluationItemAdapter.toSdk(entry.item!)),
  ];

  /// [layout] as item ids, for re-laying out a template; items without an
  /// id (not yet created) are left out.
  static List<sdk.EvaluationLayoutEntry<int>> toIdLayout(
    List<EvaluationLayoutEntry> layout,
  ) => [
    for (final entry in layout)
      if (entry.isSection)
        sdk.EvaluationLayoutSection(entry.sectionTitle!, [
          for (final item in entry.sectionItems) ?item.id,
        ])
      else if (entry.item!.id case final id?)
        sdk.EvaluationLayoutItem(id),
  ];
}
