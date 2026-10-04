import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'evaluation_item_value.dart';

/// One entry of an evaluation template's layout: an [item] outside any
/// section, or a titled section of [sectionItems] (one level only). Items are
/// carried inline. Form-local and SDK-free.
@immutable
class EvaluationLayoutEntry {
  /// An entry of either shape; prefer [EvaluationLayoutEntry.item] or
  /// [EvaluationLayoutEntry.section]. Exactly one of [item] and
  /// [sectionTitle] is set.
  const EvaluationLayoutEntry({
    this.item,
    this.sectionTitle,
    this.sectionItems = const [],
  }) : assert(
         (item == null) != (sectionTitle == null),
         'An entry is an item or a section, never both.',
       );

  /// [item], outside any section.
  const EvaluationLayoutEntry.item(EvaluationItemValue this.item)
    : sectionTitle = null,
      sectionItems = const [];

  /// A section titled [title] holding [items].
  const EvaluationLayoutEntry.section({
    required String title,
    List<EvaluationItemValue> items = const [],
  }) : item = null,
       sectionTitle = title,
       sectionItems = items;

  /// Builds an entry from [toMap]'s output.
  factory EvaluationLayoutEntry.fromMap(Map<String, dynamic> map) {
    final item = map['item'] as Map<String, dynamic>?;
    if (item != null) {
      return EvaluationLayoutEntry.item(EvaluationItemValue.fromMap(item));
    }
    return EvaluationLayoutEntry.section(
      title: map['sectionTitle'] as String? ?? '',
      items: [
        for (final i in map['sectionItems'] as List? ?? const [])
          EvaluationItemValue.fromMap(i as Map<String, dynamic>),
      ],
    );
  }

  /// Builds an entry from [toJson]'s output.
  factory EvaluationLayoutEntry.fromJson(String source) =>
      EvaluationLayoutEntry.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// The item, for an item entry.
  final EvaluationItemValue? item;

  /// The title, for a section entry.
  final String? sectionTitle;

  /// The section's items, in order; empty for an item entry.
  final List<EvaluationItemValue> sectionItems;

  /// Whether the entry is a section.
  bool get isSection => sectionTitle != null;

  /// The items this entry holds, in order.
  List<EvaluationItemValue> get items => item == null ? sectionItems : [item!];

  /// Every item of [layout], in reading order.
  static List<EvaluationItemValue> flatten(
    List<EvaluationLayoutEntry> layout,
  ) => [for (final e in layout) ...e.items];

  /// A copy with the given fields replaced; nullable fields take a getter so
  /// they can be cleared.
  EvaluationLayoutEntry copyWith({
    EvaluationItemValue? Function()? item,
    String? Function()? sectionTitle,
    List<EvaluationItemValue>? sectionItems,
  }) => EvaluationLayoutEntry(
    item: item != null ? item() : this.item,
    sectionTitle: sectionTitle != null ? sectionTitle() : this.sectionTitle,
    sectionItems: sectionItems ?? this.sectionItems,
  );

  /// The entry as a map.
  Map<String, dynamic> toMap() => {
    'item': item?.toMap(),
    'sectionTitle': sectionTitle,
    'sectionItems': [for (final i in sectionItems) i.toMap()],
  };

  /// The entry as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'EvaluationLayoutEntry(item: $item, sectionTitle: $sectionTitle, '
      'sectionItems: $sectionItems)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationLayoutEntry &&
          other.item == item &&
          other.sectionTitle == sectionTitle &&
          listEquals(other.sectionItems, sectionItems);

  @override
  int get hashCode =>
      Object.hash(item, sectionTitle, Object.hashAll(sectionItems));
}
