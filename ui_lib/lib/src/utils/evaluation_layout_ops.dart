import '../models/evaluation_item_value.dart';
import '../models/evaluation_layout_entry.dart';
import '../models/evaluation_layout_position.dart';

/// Pure edits of a layout, each returning a new list.
///
/// Moving follows the outline as the designer sees it: an item moving down
/// onto a section enters it as its first item, one moving up onto a section
/// joins it as its last; an item at either end of a section moves out of
/// it; a section moves as a block among the top-level entries.
abstract final class EvaluationLayoutOps {
  /// Every outline row of [layout], in display order: each entry, followed
  /// for a section by its items.
  static List<EvaluationLayoutPosition> positions(
    List<EvaluationLayoutEntry> layout,
  ) => [
    for (final (i, e) in layout.indexed) ...[
      EvaluationLayoutPosition(entry: i),
      for (var j = 0; j < e.sectionItems.length; j++)
        EvaluationLayoutPosition(entry: i, child: j),
    ],
  ];

  /// The item at [pos], or `null` for a section header.
  static EvaluationItemValue? itemAt(
    List<EvaluationLayoutEntry> layout,
    EvaluationLayoutPosition pos,
  ) {
    final entry = layout[pos.entry];
    final child = pos.child;
    return child == null ? entry.item : entry.sectionItems[child];
  }

  /// [layout] with the row at [pos] moved one place by [delta] (−1 up,
  /// +1 down), or `null` when it cannot move that way.
  static List<EvaluationLayoutEntry>? move(
    List<EvaluationLayoutEntry> layout,
    EvaluationLayoutPosition pos,
    int delta,
  ) {
    final child = pos.child;
    if (child != null) return moveInSection(layout, pos.entry, child, delta);
    final i = pos.entry;
    final j = i + delta;
    if (j < 0 || j >= layout.length) return null;
    final entry = layout[i];
    final neighbour = layout[j];
    final next = [...layout];
    if (!entry.isSection && neighbour.isSection) {
      final items = [...neighbour.sectionItems];
      delta < 0 ? items.add(entry.item!) : items.insert(0, entry.item!);
      next[j] = neighbour.copyWith(sectionItems: items);
      return next..removeAt(i);
    }
    next[i] = neighbour;
    next[j] = entry;
    return next;
  }

  /// [layout] with item [child] of section [entry] moved by [delta]: within
  /// the section, or out of it past either end.
  static List<EvaluationLayoutEntry>? moveInSection(
    List<EvaluationLayoutEntry> layout,
    int entry,
    int child,
    int delta,
  ) {
    final section = layout[entry];
    final items = [...section.sectionItems];
    final target = child + delta;
    final next = [...layout];
    if (target < 0 || target >= items.length) {
      final item = items.removeAt(child);
      next[entry] = section.copyWith(sectionItems: items);
      return next..insert(
        target < 0 ? entry : entry + 1,
        EvaluationLayoutEntry.item(item),
      );
    }
    items.insert(target, items.removeAt(child));
    next[entry] = section.copyWith(sectionItems: items);
    return next;
  }

  /// [layout] without the row at [pos]. A removed section leaves its items
  /// in its place, outside any section.
  static List<EvaluationLayoutEntry> remove(
    List<EvaluationLayoutEntry> layout,
    EvaluationLayoutPosition pos,
  ) {
    final next = [...layout];
    final entry = layout[pos.entry];
    final child = pos.child;
    if (child != null) {
      next[pos.entry] = entry.copyWith(
        sectionItems: [...entry.sectionItems]..removeAt(child),
      );
      return next;
    }
    next.removeAt(pos.entry);
    if (entry.isSection) {
      next.insertAll(pos.entry, [
        for (final item in entry.sectionItems) EvaluationLayoutEntry.item(item),
      ]);
    }
    return next;
  }

  /// [layout] with the item at [pos] replaced by [item].
  static List<EvaluationLayoutEntry> replaceItem(
    List<EvaluationLayoutEntry> layout,
    EvaluationLayoutPosition pos,
    EvaluationItemValue item,
  ) {
    final next = [...layout];
    final entry = layout[pos.entry];
    final child = pos.child;
    next[pos.entry] = child == null
        ? EvaluationLayoutEntry.item(item)
        : entry.copyWith(
            sectionItems: [...entry.sectionItems]..[child] = item,
          );
    return next;
  }

  /// [layout] with [item] added at the end, or at the end of the section at
  /// index [section].
  static List<EvaluationLayoutEntry> appendItem(
    List<EvaluationLayoutEntry> layout,
    EvaluationItemValue item, {
    int? section,
  }) {
    if (section == null) return [...layout, EvaluationLayoutEntry.item(item)];
    final entry = layout[section];
    return [...layout]
      ..[section] = entry.copyWith(
        sectionItems: [...entry.sectionItems, item],
      );
  }

  /// [layout] with an empty section titled [title] at the end.
  static List<EvaluationLayoutEntry> appendSection(
    List<EvaluationLayoutEntry> layout,
    String title,
  ) => [...layout, EvaluationLayoutEntry.section(title: title)];

  /// [layout] with the section at index [section] retitled [title].
  static List<EvaluationLayoutEntry> renameSection(
    List<EvaluationLayoutEntry> layout,
    int section,
    String title,
  ) =>
      [...layout]
        ..[section] = layout[section].copyWith(sectionTitle: () => title);

  /// Whether [layout] holds at least one question.
  static bool hasQuestion(List<EvaluationLayoutEntry> layout) =>
      EvaluationLayoutEntry.flatten(
        layout,
      ).any((item) => item.kind.isQuestion);

  /// Whether every section of [layout] has a title.
  static bool sectionsTitled(List<EvaluationLayoutEntry> layout) => layout
      .where((e) => e.isSection)
      .every((e) => e.sectionTitle!.trim().isNotEmpty);
}
